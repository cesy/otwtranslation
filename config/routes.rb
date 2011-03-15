Rails.application.routes.draw do
  mount_at = OtwtranslationConfig.MOUNT_AT
  
  get mount_at => 'otwtranslation/home#index', :as => 'otwtranslation_home'
  
  get "#{mount_at}/toggle_tools" => 'otwtranslation/home#toggle_tools',
  :as => 'otwtranslation_toggle_tools'

  get "#{mount_at}/phrases" => 'otwtranslation/phrases#index',
  :as => 'otwtranslation_phrases'

  get "#{mount_at}/phrases/:id" => 'otwtranslation/phrases#show',
  :as => 'otwtranslation_phrase'
  
  get "#{mount_at}/sources" => 'otwtranslation/sources#index',
  :as => 'otwtranslation_sources'

  get "#{mount_at}/sources/:id" => 'otwtranslation/sources#show',
  :as => 'otwtranslation_source'
  
  get "#{mount_at}/languages" => 'otwtranslation/languages#index',
  :as => 'otwtranslation_languages'

  get "#{mount_at}/languages/new" => 'otwtranslation/languages#new',
  :as => 'otwtranslation_new_language'

  match "#{mount_at}/languages/" => 'otwtranslation/languages#create',
  :as => 'otwtranslation_post_language', :via => [:post]
  
  get "#{mount_at}/languages/:id" => 'otwtranslation/languages#show',
  :as => 'otwtranslation_language'
  
end

