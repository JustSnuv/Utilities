/**
 * CacheMaid.js - The ultimate automated maintenance utility for Discord bots.
 * Designed to handle memory management, cache eviction, and database health.
 * 
 * Version - 1.0
 * Creator - @Snuv
 * Contributer - None
 */

const { warn } = require('node:console');
const Snowflake = require('nodejs-snowflake');

const GLOBAL_MAP = new Map();

module.exports = {
    /**
     * Generates a map that can be used to cache things and can be accessed via other maid commands using the asigned snowflake or included entryName.
     * @param {string} - entryName
     */
    new: async (entryName) => {
        const newID = entryName || Snowflake.nextId();
        const newMapEntry = {
            id: newID,
            ts: Date.now(),
            map: new Map()
        };
        GLOBAL_MAP.set(newID, newMapEntry);
        return newMapEntry
    },

    /**
     * Adds a existing map to the maid
     * @param {[]} - map
     * @param {string} - entryName
     */
    add: async (map, entryName) => {
        const newID = entryName || Snowflake.nextId();
        const newMapEntry = {
            id: newID,
            ts: Date.now(),
            map: map
        };
        GLOBAL_MAP.set(newID, newMapEntry);
        return newMapEntry
    },

    /**
     * Update a existing map in the cache
     * @param {string} - id
     * @param {[]} - map
     */
    update: async (id, map) => {
        if (!GLOBAL_MAP.has(id)) {
            console.warn(`attempted to update a map that is not in entry: ${id}`);
            return;
        }

        const entry = GLOBAL_MAP.get(id);
        entry.map = map;
    },
    
    /**
     * Allows you to check if a map exist's in the entry
     * @param {string} - id
     */
    exist: (id) => GLOBAL_MAP.has(id),

    /**
     * Clears one or more maps from entry
     * @param {string | string[]} ids - single Snowflake or array of Snowflakes
     */
    clear: (ids) => {
        if (!Array.isArray(ids)) ids = [ids];

        for (const id of ids) {
            if (!GLOBAL_MAP.has(id)) {
                console.warn(`attempted to clear a map that is not in entry: ${id}`);
                continue;
            }
            GLOBAL_MAP.get(id).map.clear();
        }
    },

    /**
     * Removes one or more maps from entry
     * @param {string | string[]} ids - single Snowflake or array of Snowflakes
     */
    remove: (ids) => {
        if (!Array.isArray(ids)) ids = [ids];

        for (const id of ids) {
            if (!GLOBAL_MAP.has(id)) {
                console.warn(`attempted to remove a map that is not in entry: ${id}`);
                continue;
            }
            GLOBAL_MAP.get(id).map.clear();
            GLOBAL_MAP.delete(id);
        }
    },

    /**
     * Removes one or more maps from entry after a set time
     * @param {string | string[]} ids - single Snowflake or array of Snowflakes
     * @param {number} time - delay in milliseconds
     */
    debris: (ids, time) => {
        if (!Array.isArray(ids)) ids = [ids];

        setTimeout(() => {
            for (const id of ids) {
                if (!GLOBAL_MAP.has(id)) {
                    console.warn(`attempted to remove a map that is not in entry: ${id}`);
                    continue;
                }
                GLOBAL_MAP.get(id).map.clear();
                GLOBAL_MAP.delete(id);
            }
        }, time);
    },


    /**
     * Evicts the oldest entries in a Map if it exceeds a maximum size
     * @param {string | string[]} ids - single Snowflake or array of Snowflakes
     * @param {number} maxSize - max map size
     */
    evict: (ids, maxSize) => {
        if (!Array.isArray(ids)) ids = [ids];

        for (const id of ids) {
            if (!GLOBAL_MAP.has(id)) {
                console.warn(`attempted to evict a map that is not in entry: ${id}`);
                continue;
            }

            const entry = GLOBAL_MAP.get(id);
            const map = entry.map;

            if (map.size <= maxSize) continue;

            const sortedKeys = [...map.entries()]
                .sort((a, b) => (a[1].ts || 0) - (b[1].ts || 0))
                .map(([key]) => key);

            const toRemove = map.size - maxSize;
            for (let i = 0; i < toRemove; i++) {
                map.delete(sortedKeys[i]);
            }

            console.log(`[MAID] Evicted ${toRemove} entries from map ${id}.`);
        }
    },

    /**
     * Removes older entries via age
     * @param {number} maxAge - max age for a cache
     */
    sweep: (maxAge) => {
        const now = Date.now();
        for (const [id, entry] of GLOBAL_MAP.entries()) {
            if (now - entry.ts > maxAge) {
                GLOBAL_MAP.delete(id);
            }
        }
    }
};
