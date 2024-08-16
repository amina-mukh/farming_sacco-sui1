module farming_sacco::farming_sacco {
    use sui::sui::SUI;
    use std::string::String;
    use sui::coin::{Self, Coin};
    use sui::clock::{Self, Clock};
    use sui::balance::{Self, Balance};

    // Error codes for handling various scenarios
    const EInsufficientFunds: u64 = 0; // Error when funds are inadequate
    const EInvalidMember: u64 = 1; // Error for an invalid member
    const EInvalidInvoice: u64 = 2; // Error for an invalid invoice
    const EUnauthorized: u64 = 3; // Error when an action is unauthorized

    // Represents the core contract of the farming sacco
    public struct SaccoContract has key, store {
        id: UID, // Unique identifier for the contract
        contract_address: address, // Address of the sacco contract
        unit_price: u64, // Cost per unit of farming produce
        sacco_wallet: Balance<SUI>, // Balance held by the sacco
        late_fee: u64, // Fee applied for overdue payments
        overdue_duration: u64, // Time duration after which payments are overdue
    }

    // Defines the structure of a sacco member
    public struct Member has key, store {
        id: UID, // Unique member identifier
        member_code: String, // Unique code assigned to the member
        member_wallet: Balance<SUI>, // Member's balance of SUI tokens
        invoices: vector<Invoice>, // Collection of invoices for the member
        produce_units: u64, // Amount of produce requested by the member
        principal_address: address, // Address of the member
    }

    // Details the invoice issued to a member
    public struct Invoice has key, store {
        id: UID, // Unique invoice identifier
        member_id: ID, // Identifier of the member for whom the invoice is issued
        units_billed: u64, // Number of units billed in the invoice
        total_amount: u64, // Total amount due on the invoice in SUI tokens
        due_timestamp: u64, // Timestamp marking the due date
        is_paid: bool, // Status indicating whether the invoice has been settled
    }

    // Initializes the sacco contract with default settings
    fun init(
        ctx: &mut TxContext
    ) {
        let sacco_contract = SaccoContract {
            id: object::new(ctx),
            contract_address: tx_context::sender(ctx),
            unit_price: 10, // Default price per unit of produce
            late_fee: 5, // Default fee for overdue payments
            sacco_wallet: balance::zero<SUI>(), // Start with zero balance
            overdue_duration: 1000000, // Set overdue duration in milliseconds
        };

        let contract_address = tx_context::sender(ctx);
        transfer::transfer(sacco_contract, contract_address);
    }

    // Register a new member in the sacco
    public fun register_member(
        member_code: String,
        principal_address: address,
        ctx: &mut TxContext
    ) : Member {
        let id = object::new(ctx);
        Member {
            id,
            member_code,
            member_wallet: balance::zero<SUI>(),
            invoices: vector::empty<Invoice>(),
            produce_units: 0,
            principal_address,
        }
    }

    // Request farming produce units for a member
    public fun request_produce(
        member: &mut Member,
        sacco_contract: &SaccoContract,
        units: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(member.principal_address == tx_context::sender(ctx), EInvalidMember);
        member.produce_units = member.produce_units + units;
        let total_amount = units * sacco_contract.unit_price;
        let invoice = Invoice {
            id: object::new(ctx),
            member_id: object::id(member),
            units_billed: units,
            total_amount,
            due_timestamp: clock::timestamp_ms(clock) + sacco_contract.overdue_duration,
            is_paid: false,
        };
        vector::push_back(&mut member.invoices, invoice);
    }

    // Pay an invoice from a member's wallet
    public fun pay_invoice_from_wallet(
        member: &mut Member,
        sacco_contract: &mut SaccoContract,
        invoice: &mut Invoice,
        ctx: &mut TxContext
    ) {
        assert!(member.principal_address == tx_context::sender(ctx), EInvalidMember);
        assert!(invoice.member_id == object::id(member), EInvalidInvoice);
        assert!(!invoice.is_paid, EInvalidInvoice);
        assert!(balance::value(&member.member_wallet) >= invoice.total_amount, EInsufficientFunds);
        let invoice_amount = coin::take(&mut member.member_wallet, invoice.total_amount, ctx);
        transfer::public_transfer(invoice_amount, sacco_contract.contract_address);
        invoice.is_paid = true;
    }

    // Pay an invoice directly with a specified amount
    public fun pay_invoice_directly(
        member: &mut Member,
        sacco_contract: &mut SaccoContract,
        invoice: &mut Invoice,
        amount: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        assert!(member.principal_address == tx_context::sender(ctx), EInvalidMember);
        assert!(invoice.member_id == object::id(member), EInvalidInvoice);
        assert!(!invoice.is_paid, EInvalidInvoice);
        let payment_amount = coin::value(&amount);
        assert!(payment_amount >= invoice.total_amount, EInsufficientFunds);
        let invoice_amount = coin::into_balance(amount);
        balance::join(&mut sacco_contract.sacco_wallet, invoice_amount);
        invoice.is_paid = true;
    }

    // Update the number of produce units for a member
    public fun update_produce_units(
        member: &mut Member,
        units: u64,
        ctx: &mut TxContext
    ) {
        assert!(member.principal_address == tx_context::sender(ctx), EInvalidMember);
        member.produce_units = member.produce_units - units;
    }

    // Withdraw funds from a member's wallet
    public fun withdraw(
        member: &mut Member,
        amount: u64,
        ctx: &mut TxContext
    ) {
        assert!(member.principal_address == tx_context::sender(ctx), EUnauthorized);
        assert!(balance::value(&member.member_wallet) >= amount, EInsufficientFunds);
        let withdraw_amount = coin::take(&mut member.member_wallet, amount, ctx);
        transfer::public_transfer(withdraw_amount, member.principal_address);
    }

    // View remaining produce units for a member
    public fun view_remaining_units(
        member: &Member,
    ) : u64 {
        member.produce_units
    }

    // View unpaid invoices for a member
    public fun view_unpaid_invoices(
        member: &Member,
    ) : vector<ID> {
        let mut unpaid_invoices = vector::empty<ID>();
        let len: u64 = vector::length(&member.invoices);
        let mut i = 0_u64;
        while (i < len) {
            let invoice = &member.invoices[i];
            if (!invoice.is_paid) {
                let id = object::uid_to_inner(&invoice.id);
                unpaid_invoices.push_back(id);
            };
            i = i + 1;
        };
        unpaid_invoices
    }

    // Apply late fees to unpaid invoices for a member
    public fun apply_late_fees(
        member: &mut Member,
        sacco_contract: &SaccoContract,
        clock: &Clock,
        _ctx: &mut TxContext
    ) {
        let len: u64 = vector::length(&member.invoices);
        let mut i = 0_u64;
        while (i < len) {
            let invoice = &mut member.invoices[i];
            if ((!invoice.is_paid) && (invoice.due_timestamp < clock::timestamp_ms(clock))) {
                let late_fee = sacco_contract.late_fee;
                let amount = invoice.total_amount + late_fee;
                invoice.total_amount = amount;
            };
            i = i + 1;
        };
    }
}
