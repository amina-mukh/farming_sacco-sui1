# Farming SACCO Module

## Overview

The **Farming SACCO Module** is a smart contract designed for managing a cooperative agricultural society, or SACCO. This module allows members to register, request produce units, manage invoices, and perform various financial transactions. It also includes functionalities for handling late fees and querying remaining units or unpaid invoices.

## Key Features

- **Member Registration**: Register new members with unique codes and addresses.
- **Produce Request**: Request farming produce units and generate corresponding invoices.
- **Invoice Payment**: Pay invoices either directly or from a member’s wallet.
- **Balance Management**: Deposit and withdraw SUI tokens to/from a member’s wallet.
- **Invoice Management**: View unpaid invoices and apply late fees for overdue payments.
- **Produce Unit Management**: Update and view remaining produce units for members.

## Prerequisites

- **SUI Network**: This module operates on the SUI blockchain network.
- **SUI Tokens**: Required for transactions and payments within the module.

## Structure

### Modules and Structs

1. **SaccoContract**: Represents the main contract managing the SACCO, including unit price, wallet balance, late fee, and overdue duration.
2. **Member**: Represents a SACCO member with a unique ID, wallet balance, and a list of invoices.
3. **Invoice**: Represents an invoice issued to a member, including billing details and payment status.

### Functions

- **init**: Initializes the SACCO contract with default settings.
- **register_member**: Registers a new member in the SACCO.
- **request_produce**: Requests produce units and generates an invoice for the member.
- **pay_invoice_from_wallet**: Pays an invoice using the member’s wallet balance.
- **pay_invoice_directly**: Pays an invoice directly with a specified amount of SUI tokens.
- **update_produce_units**: Updates the number of produce units available to a member.
- **withdraw**: Withdraws funds from a member’s wallet.
- **view_remaining_units**: Views the remaining produce units available to a member.
- **view_unpaid_invoices**: Views all unpaid invoices for a member.
- **apply_late_fees**: Applies late fees to overdue invoices.

## Usage

### Initialization

To initialize the SACCO contract, deploy it using the `init` function. This sets up the contract with default values.

### Registering Members

Use the `register_member` function to add new members to the SACCO. Provide a unique member code and the member’s address.

### Managing Produce Requests

Members can request produce units by calling `request_produce`. This will generate an invoice based on the requested units.

### Payments

- **From Wallet**: To pay an invoice from a member’s wallet, use `pay_invoice_from_wallet`.
- **Direct Payment**: To pay an invoice directly with a specific amount, use `pay_invoice_directly`.

### Balance and Invoice Management

- **Deposit**: Add SUI tokens to a member’s wallet using the `deposit` function.
- **Withdraw**: Withdraw SUI tokens from a member’s wallet using the `withdraw` function.
- **View Units**: Check remaining produce units with `view_remaining_units`.
- **View Invoices**: List unpaid invoices using `view_unpaid_invoices`.

### Handling Late Fees

The `apply_late_fees` function can be used to apply late fees to invoices that have not been paid by their due date.

## Error Codes

- **EInsufficientFunds**: Insufficient funds for the operation.
- **EInvalidMember**: Member not recognized or unauthorized.
- **EInvalidInvoice**: Invoice is invalid or already paid.
- **EUnauthorized**: Unauthorized access or operation.

## Contributing

Contributions are welcome. Please submit issues, feature requests, or pull requests through the project's repository.

# farming_sacco-sui1
