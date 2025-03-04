class Otwtranslation::RulesController < ApplicationController
  include Otwtranslation::CommonMethods
  before_filter :otwtranslation_only, :except => :select


  def new
    @rule = Otwtranslation::GeneralRule.new(:language_short => params[:id])
  end

  
  def edit
    @rule = Otwtranslation::ContextRule.find(params[:id])
  end


  def update
    
    @rule = Otwtranslation::ContextRule.find(params[:id])
    @rule.description = params[:otwtranslation_context_rule][:description]
    @rule.conditions = trim_condition_action_params(params[:otwtranslation_context_rule][:conditions])
    @rule.actions = trim_condition_action_params(params[:otwtranslation_context_rule][:actions])
    
    if @rule.save
      redirect_to otwtranslation_language_path(@rule.language_short)
    else
      msg = 'There was a problem saving the rule:' +
        prettify_error_messages(@rule)
      flash[:error] = msg.html_safe
      render(:action => 'edit') && return 
    end
  end

  def create
    type = "#{params[:otwtranslation_context_rule][:type].capitalize}Rule"
    @rule = Otwtranslation.const_get(type).new(params[:otwtranslation_context_rule])
    @rule.language_short = params[:id]
    @rule.conditions = trim_condition_action_params(@rule.conditions)
    @rule.actions = trim_condition_action_params(@rule.actions)

    render(:action => 'new') && return if params[:commit].downcase == "set type"

    if @rule.save
      redirect_to otwtranslation_language_path(@rule.language_short)
    else
      msg = 'There was a problem saving the rule:' +
        prettify_error_messages(@rule)
      flash[:error] = msg.html_safe
      render(:action => 'new') && return 
    end
  end


  def confirm_destroy
    respond_to do |format|
      format.html do
        @rule = Otwtranslation::ContextRule.find(params[:id])
      end
      format.js do
        @rule_id = params[:id]
      end
    end
  end

  
  def move_up
    rule = Otwtranslation::ContextRule.find(params[:id])
    rule.move_higher
    redirect_to otwtranslation_language_path(rule.language_short)
  end

  
  def move_down
    rule = Otwtranslation::ContextRule.find(params[:id])
    rule.move_lower
    redirect_to otwtranslation_language_path(rule.language_short)
  end

  
  def destroy
    @rule = Otwtranslation::ContextRule.find(params[:id])
    @rule.destroy
    respond_to do |format|
      format.html do
        redirect_to otwtranslation_language_path(@rule.language_short)
      end
      format.js do
      end
    end
  end

  
  private
  
  def trim_condition_action_params(p)
    trimmed = []
    p.each_slice(2) do |name, parameters|
      parameters = Otwtranslation::ParameterParser.tokenize(parameters)
      trimmed << [name, parameters] unless name.blank?
    end
    return trimmed
  end
end

