class EthBalanceService
  class << self
    def get_house_balance
      begin
        client = Eth::Client.create(BlockchainConfig.rpc_url)
        abi = ContractAbiService.load_abi(BlockchainConfig.contract_abi_name)
        contract_address = BlockchainConfig.contract_address
        
        contract = Eth::Contract.from_abi(
          name: "TwoPartyWarGame",
          address: contract_address,
          abi: abi
        )
        
        # Get the contract balance directly using getContractBalance
        balance_wei = client.call(contract, "getContractBalance")

        # Get the gacha token address from the contract
        gacha_token_address = client.call(contract, "gachaToken")
        Rails.logger.info "Retrieved gacha token address: #{gacha_token_address}"
        Rails.logger.info "Expected address from Remix: 0x7dfddf0aa8084df7ed63f1ddbc0c1dce436a5e8c"
        Rails.logger.info "Addresses match: #{gacha_token_address&.downcase == '0x7dfddf0aa8084df7ed63f1ddbc0c1dce436a5e8c'.downcase}"
        
        # Get gacha token total supply using contract wrapper like in rake script
        gacha_total_supply = 0
        begin
          Rails.logger.info "Attempting to fetch gacha token total supply..."
          Rails.logger.info "Gacha token address: #{gacha_token_address}"
          
          # Create a simple ERC20 contract wrapper for the gacha token
          # Using the same pattern as the rake script
          gacha_contract = Eth::Contract.from_abi(
            name: "GachaToken",
            address: gacha_token_address,
            abi: [
              {
                "inputs" => [],
                "name" => "totalSupply",
                "outputs" => [{"name" => "", "type" => "uint256"}],
                "stateMutability" => "view",
                "type" => "function"
              }
            ]
          )
          
          Rails.logger.info "Created gacha token contract wrapper"
          Rails.logger.info "Calling totalSupply on contract..."
          
          # Use the same pattern as rake script: client.call(contract, "functionName")
          result = client.call(gacha_contract, "totalSupply")
          
          Rails.logger.info "Raw RPC result: #{result} (class: #{result.class})"
          
          # Convert wei result to ether (divide by 1e18)
          if result && result != 0
            gacha_total_supply = result.to_f / 1e18
            Rails.logger.info "Gacha token total supply in wei: #{result}"
            Rails.logger.info "Converted to tokens: #{gacha_total_supply}"
          else
            Rails.logger.warn "Empty or invalid result from totalSupply call: #{result.inspect}"
            gacha_total_supply = 0
          end
        rescue => e
          Rails.logger.error "Error fetching gacha token total supply: #{e.class}: #{e.message}"
          Rails.logger.error "Backtrace: #{e.backtrace.first(5).join("\n")}"
          gacha_total_supply = 0
        end
        
        balance_eth = balance_wei.to_f / (10**18)

        {
          gacha_token_address: gacha_token_address,
          contract_address: contract_address,
          gacha_total_supply: gacha_total_supply,
          balance_wei: balance_wei,
          balance_eth: balance_eth,
          success: true
        }
      rescue => e
        Rails.logger.error "Failed to fetch house ETH balance: #{e.message}"
        {
          gacha_token_address: nil,
          contract_address: BlockchainConfig.contract_address,
          gacha_total_supply: 0,
          balance_wei: 0,
          balance_eth: 0,
          success: false,
          error: e.message
        }
      end
    end
  end
end
