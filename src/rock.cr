# Rock
# The open-source static blog system written in Crystal (https://crystal-lang.org/)
# Created by Jesse Horne (https://jessehorne.github.io)
# Source: https://github.com/jessehorne/rock

require "dotenv"
require "kemal"
require "file_utils"
require "markdown"
require "crustache"

Dotenv.load!

# Remove public directory if it exists
if File.exists?("public/")
    FileUtils.rm_r("public/")
    FileUtils.mkdir("public/")
end

# Compile Markdown Pages
template_nav = [] of String
splitted_nav = ENV["BLOG_NAV"].split(",")
splitted_nav.each { |page|
    page = page.downcase
    file_path = "src/pages/#{page}.md"
    built_path = "public/#{page}.html"

    template_nav << page

    if File.exists?(file_path) && !File.exists?(built_path)
        file_content = File.read(file_path)
        compiled_content = build_page(Markdown.to_html(file_content))
        File.write(built_path, compiled_content)
    end
}

home_content = File.read("src/pages/home.md")
home_compiled = Markdown.to_html(home_content)
File.write("public/home.html", home_compiled)

# Copy CSS/JS folders to public
css_path = %(src/templates/#{ENV["BLOG_TEMPLATE"]}/css/)
js_path = %(src/templates/#{ENV["BLOG_TEMPLATE"]}/js/)
favicon_path = %(src/templates/#{ENV["BLOG_TEMPLATE"]}/favicon.ico)
webfonts_path = %(src/templates/#{ENV["BLOG_TEMPLATE"]}/webfonts/)

if File.exists?(css_path)
    FileUtils.cp_r(File.expand_path(css_path), "public/css")
end

if File.exists?(js_path)
    FileUtils.cp_r(File.expand_path(js_path), "public/js")
end

if File.exists?(favicon_path)
    FileUtils.cp(File.expand_path(favicon_path), "public/favicon.ico")
end

if File.exists?(webfonts_path)
    FileUtils.cp_r(File.expand_path(webfonts_path), "public/webfonts")
end

def build_page(content)
    return content
end

get "/" do
    home_path = "public/home.html"
    home_content = File.read("public/home.html")

    layout_path = %(src/templates/#{ENV["BLOG_TEMPLATE"]}/index.mustache)
    layout_template = Crustache.parse_file(layout_path)
    layout_data = {
        "title" => ENV["BLOG_TITLE"],
        "brand" => ENV["BLOG_BRAND"],
        "nav" => template_nav,
        "content" => home_content,
        "medium_url" => ENV["MEDIUM_URL"],
        "linkedin_url" => ENV["LINKEDIN_URL"],
        "github_url" => ENV["GITHUB_URL"]
    }

    Crustache.render layout_template, layout_data
end

get "/:page" do |env|
    page = env.params.url["page"]

    built_path = %(public/#{page}.html)
    built_content = File.read(built_path)

    layout_path = %(src/templates/#{ENV["BLOG_TEMPLATE"]}/index.mustache)
    layout_template = Crustache.parse_file(layout_path)
    layout_data = {
        "title" => ENV["BLOG_TITLE"],
        "content" => built_content
    }

    Crustache.render layout_template, layout_data
end

Kemal.run
