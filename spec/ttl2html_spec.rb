require_relative "../ttl2html"

RSpec.describe TTL2HTML do
  spec_base_dir = File.dirname(__FILE__)
  context "#new" do
    it "should construct a new instance" do
      ttl2html = TTL2HTML.new
      expect(ttl2html).not_to be_nil
    end
    it "should accept an argument" do
      ttl2html = TTL2HTML.new("config.yml")
      expect(ttl2html).not_to be_nil
      ttl2html = TTL2HTML.new(File.join(spec_base_dir, "example/example.yml"))
      expect(ttl2html).not_to be_nil
    end
  end
  context "#output_html_files" do
    it "should deal with path separators" do
      ttl2html = TTL2HTML.new(File.join(spec_base_dir, "example/example.yml"))
      expect {
        ttl2html.load_turtle(File.join(spec_base_dir, "example/example.ttl"))
        ttl2html.output_html_files
      }.not_to raise_error
    end
    it "should respect output dir" do
      ttl2html = TTL2HTML.new(File.join(spec_base_dir, "example/example.yml"))
      ttl2html.load_turtle(File.join(spec_base_dir, "example/example.ttl"))
      ttl2html.output_html_files
      expect(File.exist?("/tmp/html/a")).to be true
      expect(File.exist?("/tmp/html/a/index.html")).to be true
      expect(File.exist?("/tmp/html/a/b.html")).to be true
    end
  end
end
