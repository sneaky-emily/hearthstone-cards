require_relative 'battle_net_api'

# This is a Hearthsone specific helper class to handle marshaling the data from the API into a form the template can use
class Hearthstone
  class << self
    def cards_sample
      druid_cards = get_cards('druid')
      warlock_cards = get_cards('warlock')
      combined_cards = druid_cards + warlock_cards
      combined_cards.sample(10) # The sample built-in ensures records are not picked twice and implicitly returns the response
    end

    def card_metadata
      JSON.parse(BattleNetApi.get('metadata', { locale: 'en_US' }))
    end

    def detailed_cards
      metadata = card_metadata
      cards = cards_sample
      detailed_cards = []
      # Normally nested for loops aren't the best for performance, but Ruby's find is as efficient as it can be,
      # as it finds first match and returns immediately
      # If this was in a relational DB, it would be quick with primary and foreign keys and the DB doing the heavy lifting
      cards.each do |card|
        set = match_set(card, metadata['sets']) # Sets have a special case and can't be handled with a simple find
        rarity = metadata['rarities'].find { |r| r['id'] == card['rarityId'] }
        type = metadata['types'].find { |t| t['id'] == card['cardTypeId'] }
        h_class = metadata['classes'].find { |c| c['id'] == card['classId'] } # class by itself is a reserved word, hence the prefix
        detailed_cards << build_detailed_card(card, set, rarity, type, h_class)
      end
      detailed_cards.sort_by { |card| card[:id] }
    end

    private

    def get_cards(h_class)
      all_cards = []
      page1 = JSON.parse(BattleNetApi.get('cards', { class: h_class, manaCost: '7,8,9,10', rarity: 'legendary', locale: 'en_US' }))
      return page1['cards'] unless page1['pageCount'] > 1 # return early if there's only 1 page of results

      all_cards += page1['cards']
      (2..page1['pages']).each do |page|
        page = JSON.parse(BattleNetApi.get('cards', { class: h_class, manaCost: '7,8,9,10', rarity: 'legendary', locale: 'en_US', page: page }))
        all_cards += page['cards']
      end
      all_cards
    end

    # There is a special case for card sets, as it can't be matched just on id, legacy cards have an alias instead
    def match_set(card, sets)
      # Try to match based on set first, then try aliasID if normal ID fails
      set = sets.find { |s| s['id'] == card['cardSetId'] }
      if set.nil?
        sets.each do |s|
          next unless s.include?('aliasSetIds') # Skip this set if it does not contain any aliases

          set = s if s['aliasSetIds'].include?(card['cardSetId'])
        end
      end
      set
    end

    def build_detailed_card(card, set, rarity, type, h_class)
      {
        id: card['id'],
        image: card['image'],
        name: card['name'],
        type: type['name'],
        rarity: rarity['name'],
        set: set['name'],
        class: h_class['name']
      }
    end
  end
end
