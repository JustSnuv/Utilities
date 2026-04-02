// RateHandler.js
const CacheMaid = require('./CacheMaid');

const LIMIT_CONFIG = {
    MAX_PER_MINUTE: 3,
    WINDOW: 60_000,        // 1 minute
    MAX_USERS: 1000        // hard cap safety
};

// create a CacheMaid map for user rates
const rateCache = CacheMaid.new('rate-handler');

// increment user rate
function AddRate(userId) {
    const now = Date.now();
    const entry = rateCache.map.get(userId);

    if (!entry || (now - entry.ts > LIMIT_CONFIG.WINDOW)) {
        // reset window
        rateCache.map.set(userId, {
            count: 1,
            ts: now
        });
    } else {
        entry.count++;
    }
}

// get current rate count
function GetRate(userId) {
    const entry = rateCache.map.get(userId);
    if (!entry) return 0;

    const now = Date.now();

    // expired → delete + reset
    if (now - entry.ts > LIMIT_CONFIG.WINDOW) {
        rateCache.map.delete(userId);
        return 0;
    }

    return entry.count;
}

// use CacheMaid debris to auto-clear expired entries every window
setInterval(() => {
    const now = Date.now();

    for (const [userId, entry] of rateCache.map) {
        if (now - entry.ts > LIMIT_CONFIG.WINDOW) {
            rateCache.map.delete(userId);
        }
    }

    // hard cap protection via evict
    CacheMaid.evict('commands', LIMIT_CONFIG.MAX_USERS);

}, 60_000);

module.exports = {
    AddRate,
    GetRate
};
