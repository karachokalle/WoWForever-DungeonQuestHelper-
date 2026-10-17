-- Gear reference data for WoW Forever.
-- Season 1 tier bonuses below are transcribed from Wowhead's 1.60.1 overview.
-- Wowhead explicitly labels this data as datamined and subject to change.
-- Item IDs, exact item pieces, and boss sources are not yet available for these sets.
WFDQH_GEAR_DATA_VERSION = "2026-10-17a"
WFDQH_TIER_DATA_SOURCE = "Wowhead Forever Season 1 Tier Set Overview (datamined)"
WFDQH_TIER_DATA_URL = "https://www.wowhead.com/forever/guide/season-1-tier-set-bonus-appearance-overview"
WFDQH_GEAR_DATA_STATUS = "Pre-BiS/BiS-Empfehlungen speziell für WoW Forever sind in der verfügbaren Wowhead-Quelle noch nicht hinterlegt."

WFDQH_GEAR_CLASSES = {
    { name = "Druid", specs = { "Balance", "Feral", "Guardian", "Restoration" } },
    { name = "Hunter", specs = { "Beast Mastery" } },
    { name = "Mage", specs = { "Mage" } },
    { name = "Paladin", specs = { "Holy", "Protection", "Retribution" } },
    { name = "Priest", specs = { "Discipline/Holy", "Shadow" } },
    { name = "Rogue", specs = { "Rogue" } },
    { name = "Shaman", specs = { "Elemental", "Enhancement", "Restoration" } },
    { name = "Warlock", specs = { "Warlock" } },
    { name = "Warrior", specs = { "Arms/Fury", "Protection" } },
}

WFDQH_TIER_SETS = {
    { class = "Druid", spec = "Restoration", name = "Grovekeeper Raiment", tier = "Season 1 · Raid", bonuses = {
        { pieces = 2, text = "Spirit-Bonus" }, { pieces = 3, text = "Barkskin-Abklingzeit" },
        { pieces = 4, text = "Heilungs-/Schadensbonus" }, { pieces = 5, text = "Swiftmend-Abklingzeit" },
    } },
    { class = "Druid", spec = "Guardian", name = "Grovekeeper Rage", tier = "Season 1 · Raid", bonuses = {
        { pieces = 2, text = "Verteidigungsbonus" }, { pieces = 3, text = "Wiedergeburt in Bärenform" },
        { pieces = 4, text = "Expertise-Bonus" }, { pieces = 5, text = "Berserk-Abklingzeit" },
    } },
    { class = "Druid", spec = "Balance", name = "Grovekeeper Eclipse", tier = "Season 1 · Raid", bonuses = {
        { pieces = 2, text = "Trefferwertung" }, { pieces = 3, text = "Nature's-Grasp-Abklingzeit" },
        { pieces = 4, text = "Zauberschaden gegen Dämonen" }, { pieces = 5, text = "Insect-Swarm-Dauer" },
    } },
    { class = "Druid", spec = "Feral", name = "Grovekeeper Ferocity", tier = "Season 1 · Raid", bonuses = {
        { pieces = 2, text = "Angriffs- und Zaubertempo" }, { pieces = 3, text = "Hibernate in Katzengestalt" },
        { pieces = 4, text = "Angriffskraft gegen Dämonen" }, { pieces = 5, text = "Tiger's-Fury-Abklingzeit" },
    } },
    { class = "Hunter", spec = "Beast Mastery", name = "Wildstalker Armor", tier = "Season 1 · Raid", bonuses = {
        { pieces = 2, text = "Angriffs- und Zaubertempo" }, { pieces = 3, text = "Frost Trap/Freezing Trap-Abklingzeit" },
        { pieces = 4, text = "Angriffskraft gegen Wildtiere" }, { pieces = 5, text = "Aimed Shot/Multi-Shot-Abklingzeit" },
    } },
    { class = "Mage", spec = "Mage", name = "Manaflare Regalia", tier = "Season 1 · Raid", bonuses = {
        { pieces = 2, text = "Trefferwertung" }, { pieces = 3, text = "Counterspell-Effekt" },
        { pieces = 4, text = "Zauberschaden gegen Elementare" }, { pieces = 5, text = "Frostfire-Bolt-Effekt" },
    } },
    { class = "Paladin", spec = "Retribution", name = "Justice Battlegear", tier = "Season 1 · Raid", bonuses = {
        { pieces = 2, text = "Angriffs- und Zaubertempo" }, { pieces = 3, text = "Hammer-of-Justice-Effekt" },
        { pieces = 4, text = "Angriffskraft gegen Untote" }, { pieces = 5, text = "Judgement-Effekt" },
    } },
    { class = "Paladin", spec = "Holy", name = "Justice Armor", tier = "Season 1 · Raid", bonuses = {
        { pieces = 2, text = "Spirit-Bonus" }, { pieces = 3, text = "Blessing-of-Protection-Effekt" },
        { pieces = 4, text = "Heilungs-/Schadensbonus" }, { pieces = 5, text = "Holy-Shock-Effekt" },
    } },
    { class = "Paladin", spec = "Protection", name = "Justice Battleplate", tier = "Season 1 · Raid", bonuses = {
        { pieces = 2, text = "Verteidigungsbonus" }, { pieces = 3, text = "Turn-Undead-Effekt" },
        { pieces = 4, text = "Expertise-Bonus" }, { pieces = 5, text = "Forbearance-Effekt" },
    } },
    { class = "Priest", spec = "Discipline/Holy", name = "Vestments of Conviction", tier = "Season 1 · Raid", bonuses = {
        { pieces = 2, text = "Spirit-Bonus" }, { pieces = 3, text = "Fear-Ward-Effekt" },
        { pieces = 4, text = "Heilungs-/Schadensbonus" }, { pieces = 5, text = "Penance/Prayer-of-Mending-Effekt" },
    } },
    { class = "Priest", spec = "Shadow", name = "Raiments of Conviction", tier = "Season 1 · Raid", bonuses = {
        { pieces = 2, text = "Trefferwertung" }, { pieces = 3, text = "Shackle-Undead-Effekt" },
        { pieces = 4, text = "Zauberschaden gegen Untote" }, { pieces = 5, text = "Devouring-Plague-Effekt" },
    } },
    { class = "Rogue", spec = "Rogue", name = "Grimstitch Armor", tier = "Season 1 · Raid", bonuses = {
        { pieces = 2, text = "Trefferwertung" }, { pieces = 3, text = "Kidney-Shot-Effekt" },
        { pieces = 4, text = "Angriffskraft gegen Humanoide" }, { pieces = 5, text = "Envenom/Eviscerate-Effekt" },
    } },
    { class = "Shaman", spec = "Restoration", name = "The Spiritcaller", tier = "Season 1 · Raid", bonuses = {
        { pieces = 2, text = "Spirit-Bonus" }, { pieces = 3, text = "Feuer-/Wassertotem-Effekt" },
        { pieces = 4, text = "Heilungs-/Schadensbonus" }, { pieces = 5, text = "Riptide-Effekt" },
    } },
    { class = "Shaman", spec = "Enhancement", name = "The Spiritcaller's Rage", tier = "Season 1 · Raid", bonuses = {
        { pieces = 2, text = "Angriffs- und Zaubertempo" }, { pieces = 3, text = "Erd-/Windtotem-Effekt" },
        { pieces = 4, text = "Angriffskraft gegen Elementare" }, { pieces = 5, text = "Stormstrike-Effekt" },
    } },
    { class = "Shaman", spec = "Elemental", name = "The Spiritcaller's Storm", tier = "Season 1 · Raid", bonuses = {
        { pieces = 2, text = "Trefferwertung" }, { pieces = 3, text = "Earthbind-Totem-Effekt" },
        { pieces = 4, text = "Zauberschaden gegen Elementare" }, { pieces = 5, text = "Lava-Burst-Effekt" },
    } },
    { class = "Warlock", spec = "Warlock", name = "Demonheart Raiment", tier = "Season 1 · Raid", bonuses = {
        { pieces = 2, text = "Trefferwertung" }, { pieces = 3, text = "Banish-Effekt" },
        { pieces = 4, text = "Zauberschaden gegen Dämonen" }, { pieces = 5, text = "Life-Tap-Effekt" },
    } },
    { class = "Warrior", spec = "Arms/Fury", name = "Battlegear of Glory", tier = "Season 1 · Raid", bonuses = {
        { pieces = 2, text = "Angriffs- und Zaubertempo" }, { pieces = 3, text = "Intimidating-Shout-Effekt" },
        { pieces = 4, text = "Angriffskraft gegen Humanoide" }, { pieces = 5, text = "Recklessness-Abklingzeit" },
    } },
    { class = "Warrior", spec = "Protection", name = "Battleplate of Glory", tier = "Season 1 · Raid", bonuses = {
        { pieces = 2, text = "Verteidigungsbonus" }, { pieces = 3, text = "Intervene-Effekt" },
        { pieces = 4, text = "Expertise-Bonus" }, { pieces = 5, text = "Shield-Wall-Abklingzeit" },
    } },
}

-- No Forever-specific pre-BiS/BiS recommendations are available in the verified sources yet.
-- Keep the schema ready for later additions without presenting Classic lists as Forever data.
WFDQH_GEAR_LISTS = {}
