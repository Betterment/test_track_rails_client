require 'rbconfig'

class TesttrackCli
  include Singleton

  def project_initialized?
    File.exist?(File.join('testtrack', 'schema.yml'))
  end

  def call(*args)
    system(path, *args)
    $CHILD_STATUS
  end

  def path
    TestTrackRailsClient::Engine.root.join("vendor", "bin", "testtrack-cli", filename).to_s
  end

  def filename
    case host_os
      when /darwin/
        "testtrack.darwin"
      when /linux/
        "testtrack.linux"
      else
        raise "no testtrack binary for platform #{host_os}"
    end
  end

  private

  def host_os
    RbConfig::CONFIG['host_os']
  end
end
