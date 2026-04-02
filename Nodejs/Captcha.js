const Maid = require("./CacheMaid");
const emojis = require("../stats/emojis");

const {
    ActionRowBuilder,
    ButtonBuilder,
    ButtonStyle,
    ModalBuilder,
    TextInputBuilder,
    TextInputStyle,
} = require("discord.js");

// In-memory store for user stats (CAPTCHA count)
const userStats = new Map();

// CacheMaid map for active captchas
const activeCaptchas = Maid.new("active-captchas");

/**
 * Generate a random captcha string
 */
function generateCaptchaString() {
    const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    const length = Math.floor(Math.random() * 4) + 5;
    return Array.from({ length }, () => chars[Math.floor(Math.random() * chars.length)]).join("");
}

/**
 * Confirm a user interaction via CAPTCHA.
 */
async function confirmInteraction(interaction, client) {
    const userId = interaction.user.id;

    // Get CAPTCHA count from in-memory store
    let captchaCount = userStats.get(userId)?.CAPTCHA || 0;

    if (captchaCount < 20) {
        // Increment count in memory
        userStats.set(userId, { CAPTCHA: captchaCount + 1 });
        return true;
    }

    // Check if the user already has an active captcha
    if (activeCaptchas.map.has(userId)) return false;

    const captchaString = generateCaptchaString();

    // Store captcha and timestamp in CacheMaid map
    activeCaptchas.map.set(userId, {
        value: captchaString,
        ts: Date.now(),
    });

    // Button to start captcha
    const verifyButton = new ButtonBuilder()
        .setCustomId(`captcha_start_${userId}`)
        .setLabel("Start CAPTCHA")
        .setStyle(ButtonStyle.Primary);

    const row = new ActionRowBuilder().addComponents(verifyButton);

    await interaction.editReply({
        content: "⚠️ Please verify you are human to continue:",
        components: [row],
    });

    const collector = interaction.channel.createMessageComponentCollector({
        filter: (i) => i.customId === `captcha_start_${userId}` && i.user.id === userId,
        time: 30000,
        max: 1,
    });

    // Cleanup function
    const cleanup = () => {
        activeCaptchas.map.delete(userId);
        if (!collector.ended) collector.stop();
    };

    collector.on("collect", async (i) => {
        try {
            const modal = new ModalBuilder()
                .setCustomId(`captcha_modal_${userId}`)
                .setTitle("⚠️ Human Verification")
                .addComponents(
                    new ActionRowBuilder().addComponents(
                        new TextInputBuilder()
                            .setCustomId("captcha_input")
                            .setLabel(`Type this exactly: ${captchaString}`)
                            .setStyle(TextInputStyle.Short)
                            .setRequired(true)
                    )
                );

            await i.showModal(modal);

            const submitted = await i.awaitModalSubmit({
                time: 20000,
                filter: (m) => m.customId === `captcha_modal_${userId}` && m.user.id === userId,
            });

            const answer = submitted.fields.getTextInputValue("captcha_input").trim().toUpperCase();
            const success = answer === captchaString;

            // Reset or penalize CAPTCHA count in memory
            userStats.set(userId, { CAPTCHA: success ? 0 : 20 });

            await submitted.reply({
                content: success
                    ? `${emojis.UI_Plus} CAPTCHA passed!`
                    : `${emojis.UI_Cross} CAPTCHA failed, try again.`,
                flags: 64,
            });
        } catch (err) {
            await interaction.followUp({
                content: `${emojis.UI_Cross} CAPTCHA failed (timeout or error), try again.`,
                flags: 64,
            }).catch(() => {});
        } finally {
            cleanup(); // always free memory
        }
    });

    collector.on("end", () => {
        cleanup(); // cleanup on timeout
        interaction.editReply({
            content: `${emojis.UI_Cross} CAPTCHA timed out — please retry.`,
            components: [],
        }).catch(() => {});
    });

    // Auto-expire entries after 60s using CacheMaid debris
    Maid.debris([userId], 60_000);

    return false;
}

module.exports = confirmInteraction;
