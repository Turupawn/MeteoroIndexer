namespace :transactions do
  desc "Sync transactions from blockchain API"
  task sync: :environment do
    puts "Starting transactions sync at #{Time.current}"
    
    start_time = Time.current
    
    begin
      transactions_data = TransactionService.fetch_incremental_transactions
      
      if transactions_data.nil? || transactions_data.empty?
        puts "No transactions found from API"
      else
        puts "Found #{transactions_data.length} transactions from API"

        new_count = 0
        updated_count = 0

        transactions_data.each do |tx_data|
          begin
            existing_tx = Transaction.find_by(transaction_hash: tx_data[:hash])
            
            if existing_tx
              function_signature = nil
              if tx_data[:raw_input] && tx_data[:raw_input].length > 10
                signature_hex = tx_data[:raw_input][0, 10] # First 10 characters include "0x" + 8 hex chars
                function_signature = FunctionSignature.find_by(signature_hex: signature_hex)
              end
              
              function_signature ||= FunctionSignature.find_by(name: 'unknown')
              
              existing_tx.update!(
                sequential_id: tx_data[:sequential_id],
                method: tx_data[:method],
                from_address: tx_data[:from],
                to_address: tx_data[:to],
                value: tx_data[:value],
                fee: tx_data[:fee],
                gas_used: tx_data[:gas_used],
                gas_price: tx_data[:gas_price],
                status: tx_data[:status],
                confirmations: tx_data[:confirmations],
                block_number: tx_data[:block_number],
                timestamp: Time.parse(tx_data[:timestamp]),
                function_signature: function_signature,
                raw_input: tx_data[:raw_input],
                decoded_input: tx_data[:decoded_input]&.to_json
              )
              updated_count += 1
              puts "Updated transaction #{tx_data[:hash]} (sequential_id: #{tx_data[:sequential_id]})"
            else
              function_signature = nil
              if tx_data[:raw_input] && tx_data[:raw_input].length > 10
                signature_hex = tx_data[:raw_input][0, 10] # First 10 characters include "0x" + 8 hex chars
                function_signature = FunctionSignature.find_by(signature_hex: signature_hex)
              end
              
              function_signature ||= FunctionSignature.find_by(name: 'unknown')

              Transaction.create!(
                transaction_hash: tx_data[:hash],
                sequential_id: tx_data[:sequential_id],
                method: tx_data[:method],
                from_address: tx_data[:from],
                to_address: tx_data[:to],
                value: tx_data[:value],
                fee: tx_data[:fee],
                gas_used: tx_data[:gas_used],
                gas_price: tx_data[:gas_price],
                status: tx_data[:status],
                confirmations: tx_data[:confirmations],
                block_number: tx_data[:block_number],
                timestamp: Time.parse(tx_data[:timestamp]),
                function_signature: function_signature,
                raw_input: tx_data[:raw_input],
                decoded_input: tx_data[:decoded_input]&.to_json
              )
              new_count += 1
              puts "Created new transaction #{tx_data[:hash]} (sequential_id: #{tx_data[:sequential_id]})"
            end
          rescue => e
            puts "Error processing transaction #{tx_data[:hash]}: #{e.message}"
            Rails.logger.error "Error processing transaction #{tx_data[:hash]}: #{e.message}"
          end
        end

        puts "Transactions sync completed:"
        puts "  New transactions: #{new_count}"
        puts "  Updated transactions: #{updated_count}"
        
        # Record sync statistics for potential telegram aggregation
        TelegramNotificationService.record_sync_and_notify_if_needed(new_count)
      end
      
    rescue => e
      puts "Error in transactions sync: #{e.message}"
      puts e.backtrace.first(5).join("\n")
      Rails.logger.error "Transactions sync failed: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      
      # Send error notification
      TelegramNotificationService.send_sync_error_notification(e.message)
    end
  end



end
