# name: discourse-badgekit
# about: Displays Badgekit badges under user avatars in Discourse
# version: 0.1
# authors: Erik Christensen

register_asset "javascripts/initializers/badgekit.js.es6"

register_css <<CSS

.badgekit-badge {
  width: 45px;
  height: 45px;
}

CSS

BADGEKIT_CONFIG = YAML.load_file(File.expand_path('../config.yml', __FILE__))[Rails.env]

require 'net/http'
require 'jwt'

module ::BadgekitPlugin
  class BadgekitController < ActionController::Base
    def getBadges
      if user = User.find_by(id: params[:userId])
        email = user.email
        host = BADGEKIT_CONFIG['api']['host']
        port = BADGEKIT_CONFIG['api']['port'] ||= nil
        path = '/systems/' + BADGEKIT_CONFIG['api']['system'] + '/instances/' + email
        httpcall = Net::HTTP.new(host, port)
        
        token = JWT.encode({
          key: BADGEKIT_CONFIG['api']['key'],
          method: 'GET',
          path: path
        }, BADGEKIT_CONFIG['api']['secret'])

        headers = {
          'Authorization' => 'JWT token="' + token + '"'
        }

        resp = httpcall.get2(path, headers)
        data = JSON.parse(resp.body())
        images = data['instances'].map { |instance| {:name => instance['badge']['name'], :imageUrl => instance['badge']['imageUrl'] }}

        render json: {:badges => images}
      else
        render json: nil, :status => 404
      end
    end
  end
end

BadgekitPlugin = BadgekitPlugin

# what in the hells is happening above this line

after_initialize do
  module BadgekitPlugin
    class Engine < ::Rails::Engine
      engine_name "badgekit_plugin"
      isolate_namespace BadgekitPlugin
    end
  end

  BadgekitPlugin::Engine.routes.draw do
    get '/badgekit' => 'badgekit#getBadges'
  end

  Discourse::Application.routes.append do
    mount ::BadgekitPlugin::Engine, at: '/'
  end
end
