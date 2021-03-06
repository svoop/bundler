# frozen_string_literal: true
require "spec_helper"

RSpec.describe "bundle install with specific_platform enabled" do
  before do
    bundle "config specific_platform true"

    build_repo2 do
      build_gem("google-protobuf", "3.0.0.alpha.5.0.5.1")
      build_gem("google-protobuf", "3.0.0.alpha.5.0.5.1") {|s| s.platform = "x86_64-linux" }
      build_gem("google-protobuf", "3.0.0.alpha.5.0.5.1") {|s| s.platform = "x86-mingw32" }
      build_gem("google-protobuf", "3.0.0.alpha.5.0.5.1") {|s| s.platform = "x86-linux" }
      build_gem("google-protobuf", "3.0.0.alpha.5.0.5.1") {|s| s.platform = "x64-mingw32" }
      build_gem("google-protobuf", "3.0.0.alpha.5.0.5.1") {|s| s.platform = "universal-darwin" }

      build_gem("google-protobuf", "3.0.0.alpha.5.0.5") {|s| s.platform = "x86_64-linux" }
      build_gem("google-protobuf", "3.0.0.alpha.5.0.5") {|s| s.platform = "x86-linux" }
      build_gem("google-protobuf", "3.0.0.alpha.5.0.5") {|s| s.platform = "x64-mingw32" }
      build_gem("google-protobuf", "3.0.0.alpha.5.0.5") {|s| s.platform = "x86-mingw32" }
      build_gem("google-protobuf", "3.0.0.alpha.5.0.5")

      build_gem("google-protobuf", "3.0.0.alpha.5.0.4") {|s| s.platform = "universal-darwin" }
      build_gem("google-protobuf", "3.0.0.alpha.5.0.4") {|s| s.platform = "x86_64-linux" }
      build_gem("google-protobuf", "3.0.0.alpha.5.0.4") {|s| s.platform = "x86-mingw32" }
      build_gem("google-protobuf", "3.0.0.alpha.5.0.4") {|s| s.platform = "x86-linux" }
      build_gem("google-protobuf", "3.0.0.alpha.5.0.4") {|s| s.platform = "x64-mingw32" }
      build_gem("google-protobuf", "3.0.0.alpha.5.0.4")

      build_gem("google-protobuf", "3.0.0.alpha.5.0.3")
      build_gem("google-protobuf", "3.0.0.alpha.5.0.3") {|s| s.platform = "x86_64-linux" }
      build_gem("google-protobuf", "3.0.0.alpha.5.0.3") {|s| s.platform = "x86-mingw32" }
      build_gem("google-protobuf", "3.0.0.alpha.5.0.3") {|s| s.platform = "x86-linux" }
      build_gem("google-protobuf", "3.0.0.alpha.5.0.3") {|s| s.platform = "x64-mingw32" }
      build_gem("google-protobuf", "3.0.0.alpha.5.0.3") {|s| s.platform = "universal-darwin" }

      build_gem("google-protobuf", "3.0.0.alpha.4.0")
      build_gem("google-protobuf", "3.0.0.alpha.3.1.pre")
      build_gem("google-protobuf", "3.0.0.alpha.3")
      build_gem("google-protobuf", "3.0.0.alpha.2.0")
      build_gem("google-protobuf", "3.0.0.alpha.1.1")
      build_gem("google-protobuf", "3.0.0.alpha.1.0")
    end
  end

  let(:google_protobuf) { <<-G }
    source "file:#{gem_repo2}"
    gem "google-protobuf"
  G

  context "when on a darwin machine" do
    before { simulate_platform "x86_64-darwin-15" }

    it "locks to both the specific darwin platform and ruby" do
      install_gemfile!(google_protobuf)
      expect(the_bundle.locked_gems.platforms).to eq([pl("ruby"), pl("x86_64-darwin-15")])
      expect(the_bundle).to include_gem("google-protobuf 3.0.0.alpha.5.0.5.1 universal-darwin")
      expect(the_bundle.locked_gems.specs.map(&:full_name)).to eq(%w(
        google-protobuf-3.0.0.alpha.5.0.5.1
        google-protobuf-3.0.0.alpha.5.0.5.1-universal-darwin
      ))
    end

    it "caches both the universal-darwin and ruby gems when --all-platforms is passed" do
      gemfile(google_protobuf)
      bundle! "package --all-platforms"
      expect([cached_gem("google-protobuf-3.0.0.alpha.5.0.5.1"), cached_gem("google-protobuf-3.0.0.alpha.5.0.5.1-universal-darwin")]).
        to all(exist)
    end

    context "when adding a platform via lock --add_platform" do
      it "adds the foreign platform" do
        install_gemfile!(google_protobuf)
        bundle! "lock --add-platform=#{x64_mingw}"

        expect(the_bundle.locked_gems.platforms).to eq([rb, x64_mingw, pl("x86_64-darwin-15")])
        expect(the_bundle.locked_gems.specs.map(&:full_name)).to eq(%w(
          google-protobuf-3.0.0.alpha.5.0.5.1
          google-protobuf-3.0.0.alpha.5.0.5.1-universal-darwin
          google-protobuf-3.0.0.alpha.5.0.5.1-x64-mingw32
        ))
      end

      it "falls back on plain ruby when that version doesnt have a platform-specific gem" do
        install_gemfile!(google_protobuf)
        bundle! "lock --add-platform=#{java}"

        expect(the_bundle.locked_gems.platforms).to eq([java, rb, pl("x86_64-darwin-15")])
        expect(the_bundle.locked_gems.specs.map(&:full_name)).to eq(%w(
          google-protobuf-3.0.0.alpha.5.0.5.1
          google-protobuf-3.0.0.alpha.5.0.5.1-universal-darwin
        ))
      end
    end
  end
end
