from django.shortcuts import render
from django.conf import settings
from web3 import Web3

# Connect to Ganache
web3 = Web3(Web3.HTTPProvider("http://127.0.0.1:7545"))

# ABI and Address of the deployed contract
abi = settings.ESCROW_ABI
address = "0xDeployedContractAddress"  # Replace with the deployed contract address

# Create contract instance
escrow_contract = web3.eth.contract(address=address, abi=abi)


