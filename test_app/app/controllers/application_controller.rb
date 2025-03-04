PROFILER_SESSIONS_FILE = 'used_tags.txt'

class ApplicationController < ActionController::Base

  helper :all # include all helpers, all the time

  # Authlogic login helpers
  helper_method :current_user
  helper_method :logged_in?

  include OtwtranslationHelper

protected

  def current_user_session
    return @current_user_session if defined?(@current_user_session)
    @current_user_session = UserSession.find
  end

  def current_user
    @current_user = current_user_session && current_user_session.record
  end

  def logged_in?
    current_user.nil? ? false : true
  end

public

  # store previous page in session to make redirecting back possible
  # if already redirected once, don't redirect again.
  before_filter :store_location
  def store_location
    if session[:return_to] == "redirected"
      Rails.logger.debug "Return to back would cause infinite loop"
      session.delete(:return_to)
    else
      session[:return_to] = request.fullpath
      Rails.logger.debug "Return to: #{session[:return_to]}"
    end
  end

  # Redirect to the URI stored by the most recent store_location call or
  # to the passed default.
  def redirect_back_or_default(default = root_path)
    back = session[:return_to]
    session.delete(:return_to)
    if back
      Rails.logger.debug "Returning to #{back}"
      session[:return_to] = "redirected"
      redirect_to(back) and return
    else
      Rails.logger.debug "Returning to default (#{default})"
      redirect_to(default) and return
    end
  end

  # Filter method to prevent admin users from accessing certain actions
  def users_only
    logged_in? || access_denied
  end

  # Redirect as appropriate when an access request fails.
  #
  # The default action is to redirect to the login screen.
  #
  # Override this method in your controllers if you want to have special
  # behavior in case the user is not authorized
  # to access the requested action.  For example, a popup window might
  # simply close itself.
  def access_denied(options ={})
    store_location
    if logged_in?
      destination = home_path
      flash[:error] = ts "Sorry, you don't have permission to access the page you were trying to reach."
      redirect_to destination
    else
      destination = options[:redirect].blank? ? new_user_session_path : options[:redirect]
      flash[:error] = ts "Sorry, you don't have permission to access the page you were trying to reach. Please log in."
      redirect_to destination
    end
    false
  end

  # Filter method - prevents users from logging in as admin
  def user_logout_required
    if logged_in?
      flash[:notice] = 'Please log out of your user account first!'
      redirect_to root_path
    end
  end


  # Store the current user as a class variable in the User class,
  # so other models can access it with "User.current_user"
  before_filter :set_current_user
  def set_current_user
    User.current_user = current_user
    @current_user = current_user
  end

  def load_collection
    @collection = Collection.find_by_name(params[:collection_id]) if params[:collection_id]
  end

  def collection_maintainers_only
    logged_in? && @collection && @collection.user_is_maintainer?(current_user) || access_denied
  end

  def collection_owners_only
    logged_in? && @collection && @collection.user_is_owner?(current_user) || access_denied
  end

  @over_anon_threshold = true if @over_anon_threshold.nil?

  def get_page_title(fandom, author, title, options = {})
    # truncate any piece that is over 15 chars long to the nearest word
    if options[:truncate]
      fandom = fandom.gsub(/^(.{15}[\w.]*)(.*)/) {$2.empty? ? $1 : $1 + '...'}
      author = author.gsub(/^(.{15}[\w.]*)(.*)/) {$2.empty? ? $1 : $1 + '...'}
      title = title.gsub(/^(.{15}[\w.]*)(.*)/) {$2.empty? ? $1 : $1 + '...'}
    end

    @page_title = ""
    if logged_in? && !current_user.preference.try(:work_title_format).blank?
      @page_title = current_user.preference.work_title_format
      @page_title.gsub!(/FANDOM/, fandom)
      @page_title.gsub!(/AUTHOR/, author)
      @page_title.gsub!(/TITLE/, title)
    else
      @page_title = title + " - " + author + " - " + fandom
    end

    @page_title += " [#{ArchiveConfig.APP_NAME}]" unless options[:omit_archive_name]
    @page_title
  end

  ### GLOBALIZATION ###

#  before_filter :load_locales
#  before_filter :set_preferred_locale

#  I18n.backend = I18nDB::Backend::DBBased.new
#  I18n.record_missing_keys = false # if you want to record missing translations

  protected

  def load_locales
    @loaded_locales ||= Locale.order(:iso)
  end

  # Sets the locale
  def set_preferred_locale
    # Loading the current locale
    if session[:locale] && @loaded_locales.detect { |loc| loc.iso == session[:locale]}
      set_locale session[:locale].to_sym
    else
      set_locale Locale.find_main_cached.iso.to_sym
    end
    @current_locale = Locale.find_by_iso(I18n.locale.to_s)
  end

  ### -- END GLOBALIZATION -- ###

  public

  #### -- AUTHORIZATION -- ####

  # It is just much easier to do this here than to try to stuff variable values into a constant in environment.rb
  before_filter :set_redirects
  def set_redirects
    url_for({:controller => 'session', :action => 'new'})
  end

  def is_registered_user?
    logged_in?
  end

  def see_adult?
    params[:anchor] = "comments" if (params[:show_comments] && params[:anchor].blank?)
    Rails.logger.debug "Added anchor #{params[:anchor]}"
    return true if session[:adult]
    return false unless current_user
    return true if current_user.is_author_of?(@work)
    return true if current_user.preference && current_user.preference.adult
    return false
  end

  protected

  # Prevents banned and suspended users from adding/editing content
  def check_user_status
    if current_user.is_a?(User) && (current_user.suspended? || current_user.banned?)
      if current_user.suspended?
        flash[:error] = ts("Your account has been suspended. You may not add or edit content until your suspension has been resolved. Please contact us for more information.")
     else
        flash[:error] = ts("Your account has been banned. You are not permitted to add or edit archive content. Please contact us for more information.")
     end
      redirect_to current_user
    end
  end

  # Does the current user own a specific object?
  def current_user_owns?(item)
  	!item.nil? && current_user.is_a?(User) && (item.is_a?(User) ? current_user == item : current_user.is_author_of?(item))
  end

  # Make sure a specific object belongs to the current user and that they have permission
  # to view, edit or delete it
  def check_ownership
  	access_denied(:redirect => @check_ownership_of) unless current_user_owns?(@check_ownership_of)
  end
  def check_ownership_or_admin
     access_denied(:redirect => @check_ownership_of) unless current_user_owns?(@check_ownership_of)
  end

  # Make sure the user is allowed to see a specific page
  # includes a special case for restricted works and series, since we want to encourage people to sign up to read them
  def check_visibility
    if @check_visibility_of.respond_to?(:restricted) && @check_visibility_of.restricted && User.current_user.nil?
      redirect_to login_path(:restricted => true)
    elsif @check_visibility_of.is_a? Skin
      access_denied current_user_owns?(@check_visibility_of) || @check_visibility_of.official?
    else
      is_hidden = (@check_visibility_of.respond_to?(:visible) && !@check_visibility_of.visible) || 
                  (@check_visibility_of.respond_to?(:visible?) && !@check_visibility_of.visible?) || 
                  (@check_visibility_of.respond_to?(:hidden_by_admin?) && @check_visibility_of.hidden_by_admin?)
      can_view_hidden = current_user_owns?(@check_visibility_of)
      access_denied if (is_hidden && !can_view_hidden)
    end
  end


  private
 # With thanks from here: http://blog.springenwerk.com/2008/05/set-date-attribute-from-dateselect.html
  def convert_date(hash, date_symbol_or_string)
    attribute = date_symbol_or_string.to_s
    return Date.new(hash[attribute + '(1i)'].to_i, hash[attribute + '(2i)'].to_i, hash[attribute + '(3i)'].to_i)
  end

  public

# No longer works in rails 3 as routing got moved to middleware
# https://rails.lighthouseapp.com/projects/8994-ruby-on-rails/tickets/4444
# TODO find an alternative, see
# http://accuser.cc/posts/1-rails-3-0-exception-handling
# and
# http://github.com/vidibus/vidibus-routing_error
#  # with thanks to http://henrik.nyh.se/2008/07/rails-404
#  def render_optional_error_file(status_code)
#    case(status_code)
#      when :not_found then
#        render :template => "errors/404", :layout => 'application', :status => 404
#      when :forbidden then
#        render :template => "errors/403", :layout => 'application', :status => 403
#      when :unprocessable_entity then
#        render :template => "errors/422", :layout => 'application', :status => 422
#      when :internal_server_error then
#        render :template => "errors/500", :layout => 'application', :status => 500
#        notify_about_exception(error)
#      else
#        super
#    end
#  end

  def valid_sort_column(param, model='work')
    allowed = []
    if model.to_s.downcase == 'work'
      allowed = ['author', 'title', 'date', 'word_count', 'hit_count']
    elsif model.to_s.downcase == 'tag'
      allowed = ['name', 'created_at', 'suggested_fandoms', 'taggings_count']
    elsif model.to_s.downcase == 'collection'
      allowed = ['collections.title', 'collections.created_at', 'item_count']
    end
    !param.blank? && allowed.include?(param.to_s.downcase)
  end

  def valid_sort_direction(param)
    !param.blank? && ['asc', 'desc'].include?(param.to_s.downcase)
  end

  #### -- AUTHORIZATION -- ####

  protect_from_forgery

end
