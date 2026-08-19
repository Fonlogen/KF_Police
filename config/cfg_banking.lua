--[[
    KF_Police - Adapter fatturazione
    ----------------------------------------------------------------------------
    Il primo adapter la cui risorsa risulta `started` viene usato (ordine =
    priorita'). Gli argomenti sono descritti per nome e risolti a runtime da
    server/sv_fines.lua, cosi' aggiungere un banking nuovo non richiede codice.
]]

Config.Banking = {
    Enabled = true,
    FallbackLabel = 'Sanzione polizia',
    Society = 'society_police',
    SocietyLabel = 'LSPD',
    AccountType = 'bank',
    Reason = 'police_fine',

    Adapters = {
        {
            name = 'esx_billing',
            resource = 'esx_billing',
            export = {
                resource = 'esx_billing',
                name = 'BillPlayerByIdentifier',
                args = { 'targetIdentifier', 'officerIdentifier', 'society', 'label', 'amount' },
            },
        },
        {
            name = 'okokBilling',
            resource = 'okokBilling',
            export = {
                resource = 'okokBilling',
                name = 'CreateCustomInvoice',
                args = { 'targetSource', 'amount', 'label', 'societyLabel', 'society', 'society' },
            },
        },
        {
            name = 'okokBanking',
            resource = 'okokBanking',
            export = {
                resource = 'okokBanking',
                name = 'AddTransaction',
                args = { 'targetIdentifier', 'society', 'amount', 'label', 'reason' },
            },
            event = {
                name = 'okokBanking:AddNewTransaction',
                type = 'server',
                args = { 'targetIdentifier', 'society', 'amount', 'label' },
            },
        },
        {
            name = 'qb-banking',
            resource = 'qb-banking',
            export = {
                resource = 'qb-banking',
                name = 'CreateFine',
                args = { 'targetSource', 'amount', 'label', 'society' },
            },
        },
        {
            name = 'Renewed-Banking',
            resource = 'Renewed-Banking',
            export = {
                resource = 'Renewed-Banking',
                name = 'handleTransaction',
                args = { 'targetIdentifier', 'label', 'amount', 'label', 'society', 'targetIdentifier', 'withdraw' },
            },
        },
        {
            name = 'fd_banking',
            resource = 'fd_banking',
            export = {
                resource = 'fd_banking',
                name = 'AddTransaction',
                args = { 'targetIdentifier', 'amount', 'label', 'reason' },
            },
        },
        {
            name = 'tgg-banking',
            resource = 'tgg-banking',
            export = {
                resource = 'tgg-banking',
                name = 'AddTransaction',
                args = { 'targetIdentifier', 'amount', 'label' },
            },
        },
        {
            name = 'codem-bank',
            resource = 'codem-bank',
            event = {
                name = 'codem-bank:server:addTransaction',
                type = 'server',
                args = { 'targetIdentifier', 'amount', 'label' },
            },
        },
        {
            name = 'qs-banking',
            resource = 'qs-banking',
            export = {
                resource = 'qs-banking',
                name = 'AddTransaction',
                args = { 'targetIdentifier', 'amount', 'label' },
            },
        },
    },
}

--- Compatibilita' con i riferimenti storici.
Config.UseBilling = true
Config.BillingSociety = Config.Banking.Society
