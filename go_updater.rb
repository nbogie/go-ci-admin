#!/usr/bin/env ruby

require 'rubygems'
require 'restclient'
require 'builder'
require 'nokogiri'
require 'pp'
class GoUpdater
  def initialize(user, passwd)
    @user=user
    @passwd=passwd
    RestClient.log=STDOUT
    @basedir=File.dirname(__FILE__)
  end

  def server_and_port
    auth_part = @user.nil? ? "" : (@user + ":" + @passwd + "@")
    "http://" + auth_part + "localhost:8153"
  end

  def xget()
    o = RestClient.get(server_and_port + "/go/admin/configuration/file.xml")
    checksum = o.headers[:x_cruise_config_md5]
    orig_body = o.body
    return [checksum, orig_body]
  end

  def xsend(content, checksum)
    url = server_and_port + '/go/admin/configuration/file.xml'
    RestClient.post(url,
      {
        :xmlFile => content,
        :md5 =>checksum
      })
  end

  def save_backup(content)
    tstamp = Time.now.localtime.strftime("%Y-%m-%d-%H%M")
    fname = @basedir + "/backups/all_#{tstamp}.xml"
    File.open(fname, 'w') {|f| f.write content }
  end

  def add_pipeline(new_pipeline_xml)
    update(){ |old_xml|
      old_xml.gsub(/<\/pipelines>/, new_pipeline_xml + "\n</pipelines>")
    }
  end

  def delete_pipeline(pipeline_name)
    update(){ |old_xml|
      xml_doc = Nokogiri::XML(old_xml) {|config| config.options = Nokogiri::XML::ParseOptions::STRICT}
      n = xml_doc.xpath("//pipelines/pipeline[@name='#{pipeline_name}']")
      raise "couldn't find pipeline #{pipeline_name}" unless n.size == 1
      n.unlink
      to_go_xml(xml_doc)
    }
  end
  def rename_pipeline(old_name, new_name)
    update(){ |old_xml|
      xml_doc = Nokogiri::XML(old_xml) {|config| config.options = Nokogiri::XML::ParseOptions::STRICT}
      n = xml_doc.xpath("//pipelines/pipeline[@name='#{old_name}']")
      raise "couldn't find pipeline #{old_name}" unless n.size == 1
      n.first["name"] = new_name
      to_go_xml(xml_doc)
    }
  end

  def add_pipeline_for_branch(project_name, git_url, git_branch, git_branch_type)
    title = "#{project_name}_#{git_branch}"
    new_p = File.read(@basedir + "/pipeline_templates/template_#{project_name}_#{git_branch_type}.xml")
    new_p.gsub!(/REPLACE_TITLE/, title)
    new_p.gsub!(/REPLACE_GIT_BRANCH/, git_branch)
    new_p.gsub!(/REPLACE_GIT_URL/, git_url)
    new_p.gsub!(/REPLACE_PROJECT_NAME/, project_name)
    add_pipeline(new_p)
  end

  private

  #Update the pipeline xml on the server by processing it with the given block.
  #This takes care of getting, posting, backing up, and the checksum-matching.
  def update(&block)
    checksum, orig_body = xget()
    # save_backup(orig_body)
    new_body = yield orig_body
    xsend(new_body, checksum)
  end

  #given a nokogiri xml doc, print it out in a style like Go does, facilitating diffs
  def to_go_xml(xml_doc)
      out = xml_doc.to_xml({:encoding => 'utf-8', :indent => 2})
      out.gsub(/\/>/," />") # make the xml more like how go writes it
      out
  end

end

