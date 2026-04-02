// Cooldown.js
const CacheMaid = require("./CacheMaid");

const cooldowns = CacheMaid.new("cooldown"); // a CacheMaid map

/**
 * Check if a user is on cooldown for a command
 * @param {Interaction} interaction 
 * @param {string} command 
 * @returns {Promise<boolean>} true if still on cooldown
 */
async function checkCooldown(interaction, command) {
    const userId = interaction.user.id;

    // Get or create user's cooldown map
    let userMap = cooldowns.map.get(userId);
    if (!userMap) {
        userMap = new Map();
        cooldowns.map.set(userId, userMap);
    }

    const expiration = userMap.get(command);
    if (expiration && expiration > Date.now()) {
        const remainingSeconds = Math.ceil((expiration - Date.now()) / 1000);
        await interaction.editReply({
            content: `🕐 You are on cooldown for \`${command}\`. Please wait ${remainingSeconds} second(s).`,
            flags: 64,
        });
        return true;
    }

    return false;
}

/**
 * Set a cooldown for a user-command pair
 * @param {Interaction} interaction 
 * @param {string} command 
 * @param {number} duration in seconds
 */
function setCooldown(interaction, command, duration) {
    const userId = interaction.user.id;

    let userMap = cooldowns.map.get(userId);
    if (!userMap) {
        userMap = new Map();
        cooldowns.map.set(userId, userMap);
    }

    const expiration = Date.now() + duration * 1000;
    userMap.set(command, expiration);

    // Optional: auto-remove user's cooldown map after duration
    CacheMaid.debris([userId], duration * 1000);
}

/**
 * Edit an existing cooldown
 */
function editCooldown(interaction, command, duration) {
    setCooldown(interaction, command, duration);
}

module.exports = {
    checkCooldown,
    setCooldown,
    editCooldown,
};
