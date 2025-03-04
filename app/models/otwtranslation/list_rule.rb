class Otwtranslation::ListRule < Otwtranslation::ContextRule 

  CONDITIONS = {
    "has lesser/equal elements than" => "has_le_elements?",
    "has number of elements" => "has_number_elements?",
    "has more elements than" => "has_gt_elements?",
    "matches all" => "matches_all",
  }

  ACTIONS = {
    "replace" => "replace",
    "append" => "append",
    "prepend" => "prepend",
    "list to sentence" => "list_to_sentence"
  }


  ############################################################
  # Definition of conditions:
  

  def self.condition_has_le_elements?(value, params)
    match = false
    params.each { |param| match ||= (value.length <= param.to_i) }
    return match
  end

  def self.condition_has_number_elements?(value, params)
    match = false
    params.each { |param| match ||= (value.length == param.to_i) }
    return match
  end

  def self.condition_has_gt_elements?(value, params)
    match = false
    params.each { |param| match ||= (value.length > param.to_i) }
    return match
  end

  ############################################################
  # Definition of actions:
  
  def self.action_list_to_sentence(name, value, params)
    value.to_sentence(:words_connector => params[0],
                      :two_words_connector => params[1],
                      :last_word_connector => params[2])
  end

  ############################################################

end
