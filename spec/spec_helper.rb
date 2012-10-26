require "rack/test"
require "base64"
require_relative "../application.rb"

module RSpecMixin
  include Rack::Test::Methods
  def app() DSpaceCsvGui end
end

RSpec.configure { |c| c.include RSpecMixin }

unless defined?(SPEC_CONSTANTS)
  UPLOAD_1 = File.join(File.dirname(__FILE__), "files", "upload.zip")
  UPLOAD_2 = File.join(File.dirname(__FILE__), "files", "upload_dir.zip")
  UPLOAD_MANY_DIRS = File.join(File.dirname(__FILE__), "files", "upload_many_dirs.zip")
  UPLOAD_NOT_ZIP = File.join(File.dirname(__FILE__), "files", "UploadTest.csv")
  UPLOAD_NO_CSV = File.join(File.dirname(__FILE__), "files", "no_csv.zip")
  UPLOAD_BAD_CSV = File.join(File.dirname(__FILE__), "files", "bad_csv.zip")
  UPLOAD_MISSED_FILE = File.join(File.dirname(__FILE__), "files", "missed_file.zip")
  UPLOAD_EXTRA_FILE = File.join(File.dirname(__FILE__), "files", "extra_file.zip")
  UPLOAD_TYPO_IN_FILENAME_FIELD = File.join(File.dirname(__FILE__), "files", "typo_in_filename_field.zip")
  UPLOAD_NO_TITLE_FIELD = File.join(File.dirname(__FILE__), "files", "no_title_field.zip")
  UPLOAD_NO_RIGHTS_FIELD = File.join(File.dirname(__FILE__), "files", "no_rights_field.zip")
  UPLOAD_TWO_FILENAME_FIELDS = File.join(File.dirname(__FILE__), "files", "two_filename_fields.zip")
  PARAMS_1 = {"file" => {:tempfile => open(UPLOAD_1), :filename => "upload.zip"}}
  SPEC_CONSTANTS = true
end
