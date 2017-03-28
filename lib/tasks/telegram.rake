require 'telegram/bot'
namespace :telegram do
  desc "TODO"
  task saludar: :environment do

    def msg(bot, message, text)
      bot.api.send_message(chat_id: message.chat.id, text: text, force_reply: true)
      bot.listen do |message|
        bot.api.send_message(chat_id: message.chat.id, text: message.text.id)
      end
    end

    def negrita(text)
      "<b>" + text +  "</b>"
    end

    def opciones_general(bot, message, group)
      list = List.find(group.selected_list)
      case message.text.split[0]
      when '/hola'
        msg bot, message, "hola!!!! #{message.from.first_name}"
      when '/add', 'Add'
        @user = User.find_by_name message.from.first_name
        unless @user
          @user = User.new
          @user.name = message.from.first_name
          @user.save
        end
        unless list.users.find_by_id @user.id 
          list.users << @user
          text = "Usuario #{negrita message.from.first_name} fué agregado a la lista"
        else
          text = "Usuario #{negrita message.from.first_name}: ya está en la lista"
        end
        print_lista bot, message, list, text
      #when '/photo'
        #bot.api.send_photo(chat_id: message.chat.id, photo: Faraday::UploadIO.new('~/Desktop/transf.jpg', 'image/jpg'))
      when '/remove', 'Remove'
        begin
          @user = User.find_by_name message.from.first_name
          if (@user && list.users.find_by_id(@user.id) )
            list.users.delete(@user)
            text = "Usuario #{message.from.first_name}: deleted"
          else
            text = "Usuario #{message.from.first_name}: is not on the list"
          end
          print_lista bot, message, list, text
        rescue
          puts 'Error on remove'
          bot.api.send_message(chat_id: message.chat.id, text: 'error, contacte al administrador')
        end
      when '/list', 'List'
        print_lista bot, message, list, ''
      when '/lists', 'Lists'
        select_list_buttons bot, message, group
      when '/new_list'
        name = message.text.split.drop(1).join(' ')
        new_list = List.new( { name: name, group_id: group.id } )
        if new_list.save
          group.selected_list = new_list.id
          bot.api.send_message(chat_id: message.chat.id, text: 'Lista creada y seleccionada')
        else
          bot.api.send_message(chat_id: message.chat.id, text: 'Ya se existe una lista con ese nombre')
        end
      when '/delete_list'
        remove_list_buttons bot, message, group
      when '/menu'
        question = 'What do you want to do?'
        # See more: https://core.telegram.org/bots/api#replykeyboardmarkup
        answers =
          Telegram::Bot::Types::ReplyKeyboardMarkup
          .new(keyboard: [%w(Add Remove List), %w(Lists)], one_time_keyboard: true)
        bot.api.send_message(chat_id: message.chat.id, text: question, reply_markup: answers)
      when 'test'
        byebug
        bot.api.send_message(chat_id: message.chat.id, text: "test")
      else
        bot.api.send_message(chat_id: message.chat.id, text: 'No te entiendo')
      end
    end

    def select_list(bot, message, group)
      group_lists = group.lists.collect { |list| "#{list.id} - #{list.name}" }
      text = group_lists.join("\n")
      bot.api.send_message(chat_id: message.chat.id, text: text)
    end

    def select_list_buttons(bot, message, group)
      group_lists = group.lists.collect { |list| "#{list.id} - #{list.name}" }
      kb = []
      group_lists.each do |list|
        kb << Telegram::Bot::Types::InlineKeyboardButton.new(text: list, callback_data: list)
      end
      markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb)
      bot.api.send_message(chat_id: message.chat.id, text: 'Seleccione una lista...', reply_markup: markup)
    end

    def remove_list_buttons(bot, message, group)
      group_lists = group.lists.collect { |list| "#{list.id} - #{list.name}" }
      kb = []
      group_lists.each do |list|
        kb << Telegram::Bot::Types::InlineKeyboardButton.new(text: list, callback_data: list)
      end
      markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb)
      bot.api.send_message(chat_id: message.chat.id, parse_mode: 'HTML', text: "Lista a #{negrita 'borrar'}:", reply_markup: markup)
    end

    def get_group(chat)
      group = Group.find_by_guid chat.id
      unless group
        group = Group.new
        group.guid = chat.id
        group.name = chat.title
        group.save
      end
      group
    end

    def call_back_query_options(bot, message, group)
      case message.message.text 
      when 'Seleccione una lista...'
        group.selected_list = message.data.split[0]
        group.save
        bot.api.send_message(chat_id: message.message.chat.id, text: "lista seleccionada: #{message.data.split('-')[1].strip}")
      when "Lista a borrar:"
        lista = List.find_by_id message.data.split[0]
        if lista
          lista.users.delete_all
          lista.delete
          bot.api.send_message(chat_id: message.message.chat.id, text: "lista eliminada.")
        else
          bot.api.send_message(chat_id: message.message.chat.id, text: "No encuentro esa lista.")
        end
      else
        bot.api.send_message(chat_id: message.message.chat.id, text: "Estoy perdido...")
      end
    end

    def print_lista(bot, message, list, text)
      list_users = list.users.collect.with_index { |usuario, i|  "#{i + 1} - #{usuario.name}" }
      text << "\n" unless text.blank?
      unless list_users.empty?
        text << (negrita list.name + "\n")
        text << list_users.join("\n")
      else
        text << "No hay ningun usuario en la lista: #{negrita list.name}"
      end
      bot.api.send_message(chat_id: message.chat.id, parse_mode: 'HTML', text: text)
    end

    begin
      token = '341011349:AAEhbIfj23FiL7PbQ9gZVA2LTx-Hu64AHBU'
      Telegram::Bot::Client.run(token) do |bot|
        bot.listen do |message|
          case message
          when Telegram::Bot::Types::Message
            if message.chat.type == 'group'
              group = get_group message.chat
              opciones_general bot, message, group
            else
              bot.api.send_message(chat_id: message.chat.id, text: "solo para usar en grupos...")
            end
          when Telegram::Bot::Types::CallbackQuery
            if message.message.chat.type == 'group'
              group = get_group message.message.chat
              call_back_query_options bot, message, group
            else
              bot.api.send_message(chat_id: message.message.chat.id, text: "solo para usar en grupos...")
            end
          end
        end
      end
    rescue => e
      puts e
    end
  end # end task





# Another task




  desc "TODO"
  task test: :environment do
    token = '341011349:AAEhbIfj23FiL7PbQ9gZVA2LTx-Hu64AHBU'
    Telegram::Bot::Client.run(token) do |bot|
      bot.listen do |message|
        case message
        when Telegram::Bot::Types::CallbackQuery
          # Here you can handle your callbacks from inline buttons
          if message.data == 'touch'
            bot.api.send_message(chat_id: message.from.id, text: "Don't touch me!")
          end
        when Telegram::Bot::Types::Message
          kb = [
            Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Go to Google', url: 'https://google.com'),
            Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Touch me', callback_data: 'touch'),
            Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Switch to inline', switch_inline_query: 'some text')
          ]
          kb << Telegram::Bot::Types::InlineKeyboardButton.new(text: 'prueba', callback_data: 'prueba1 no pasa nada')
          markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb)
          bot.api.send_message(chat_id: message.chat.id, text: 'Make a choice', reply_markup: markup)
        end
      end
    end
  end
end
