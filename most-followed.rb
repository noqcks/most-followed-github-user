#!/usr/bin/env ruby

require 'faraday'
require 'json'
require 'nokogiri'

@location = ARGV[0]

abort 'Please specify a location: most-followed.rb <location>' if @location.nil?

@header = '<table cellspacing="0"><thead>
          <th scope="col">#</th>
          <th scope="col">User</th>
          <th scope="col">Followers</th>
          <th scope="col" width="30">Picture</th>
          </thead><tbody>'
@footer = '</tbody></table>'

@gh_api = Faraday.new(url: 'https://api.github.com') do |faraday|
  faraday.adapter  Faraday.default_adapter
end

@gh_html = Faraday.new(url: 'https://github.com') do |faraday|
  faraday.adapter  Faraday.default_adapter
end

def most_followers(per_page = 10)
  response = @gh_api.get "/search/users?q=sort:followers+location:#{@location}&per_page=#{per_page}"
  JSON.parse(response.body)
end

def user_page_html(user)
  response = @gh_html.get "/#{user}"
  Nokogiri::HTML(response.body)
end

def user_name(page)
  page.search('*[class="vcard-fullname d-block"]').text.strip
end

def follower_count(page, user)
  page.search("*[href=\"/#{user}?tab=followers\"]").first.css('span').text.strip
end

def markdown(json)
  output = []
  json['items'].each_with_index do |user, index|
    user_html = user_page_html(user['login'])
    output.push("<tr>  <th scope=\"row\">#{index + 1}</th>  <td><a href=\"#{user['html_url']}\">#{user['login']}</a> (#{user_name(user_html)})</td>  <td>#{follower_count(user_html, user['login'])}</td><td><img width=\"30\" height=\"30\" src=\"#{user['avatar_url']}\"></td></tr>")
  end

  pre = "#  Most Followed Github Users in #{@location}\nThis list was generated on #{Time.now}"
  final = pre + @header + output.join + @footer
  File.open('output.md', 'w') { |file| file.write(final) }
end

markdown(most_followers)
