# encoding: utf-8
require File.join(File.dirname(__FILE__), "../spec_helper.rb")

describe Her::Model::ORM do
  context "mapping data to Ruby objects" do
    before do
      api = Her::API.new
      api.setup :url => "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.get("/users/1") { |env| [200, {}, { :id => 1, :name => "Tobias Fünke" }.to_json] }
          stub.get("/users") { |env| [200, {}, [{ :id => 1, :name => "Tobias Fünke" }, { :id => 2, :name => "Lindsay Fünke" }].to_json] }
          stub.get("/admin_users") { |env| [200, {}, [{ :admin_id => 1, :name => "Tobias Fünke" }, { :admin_id => 2, :name => "Lindsay Fünke" }].to_json] }
          stub.get("/admin_users/1") { |env| [200, {}, { :admin_id => 1, :name => "Tobias Fünke" }.to_json] }
        end
      end

      spawn_model "Foo::User" do
        uses_api api
      end

      spawn_model "Foo::AdminUser" do
        uses_api api
        primary_key :admin_id
      end
    end

    it "maps a single resource to a Ruby object" do
      @user = Foo::User.find(1)
      @user.id.should == 1
      @user.name.should == "Tobias Fünke"

      @admin = Foo::AdminUser.find(1)
      @admin.id.should == 1
      @admin.name.should == "Tobias Fünke"
    end

    it "maps a collection of resources to an array of Ruby objects" do
      @users = Foo::User.all
      @users.length.should == 2
      @users.first.name.should == "Tobias Fünke"

      @users = Foo::AdminUser.all
      @users.length.should == 2
      @users.first.name.should == "Tobias Fünke"
    end

    it "handles new resource" do
      @new_user = Foo::User.new(:fullname => "Tobias Fünke")
      @new_user.new?.should be_truthy
      @new_user.new_record?.should be_truthy
      @new_user.fullname.should == "Tobias Fünke"

      @existing_user = Foo::User.find(1)
      @existing_user.new?.should be_falsey
      @existing_user.new_record?.should be_falsey
    end

    it 'handles new resource with custom primary key' do
      @new_user = Foo::AdminUser.new(:fullname => 'Lindsay Fünke', :id => -1)
      @new_user.should be_new

      @existing_user = Foo::AdminUser.find(1)
      @existing_user.should_not be_new
    end
  end

  context "mapping data, metadata and error data to Ruby objects" do
    before do
      api = Her::API.new
      api.setup :url => "https://api.example.com" do |builder|
        builder.use Her::Middleware::SecondLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.get("/users") { |env| [200, {}, { :data => [{ :id => 1, :name => "Tobias Fünke" }, { :id => 2, :name => "Lindsay Fünke" }], :metadata => { :total_pages => 10, :next_page => 2 }, :errors => ["Oh", "My", "God"] }.to_json] }
          stub.post("/users") { |env| [200, {}, { :data => { :name => "George Michael Bluth" }, :metadata => { :foo => "bar" }, :errors => ["Yes", "Sir"] }.to_json] }
        end
      end

      spawn_model :User do
        uses_api api
      end
    end

    it "handles metadata on a collection" do
      @users = User.all
      @users.metadata[:total_pages].should == 10
    end

    it "handles error data on a collection" do
      @users = User.all
      @users.errors.length.should == 3
    end

    it "handles metadata on a resource" do
      @user = User.create(:name => "George Michael Bluth")
      @user.metadata[:foo].should == "bar"
    end

    it "handles error data on a resource" do
      @user = User.create(:name => "George Michael Bluth")
      @user.response_errors.should == ["Yes", "Sir"]
    end
  end

  context "mapping data, metadata and error data in string keys to Ruby objects" do
    before do
      api = Her::API.new
      api.setup :url => "https://api.example.com" do |builder|
        builder.use Her::Middleware::SecondLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.get("/users") { |env| [200, {}, { 'data' => [{ :id => 1, :name => "Tobias Fünke" }, { :id => 2, :name => "Lindsay Fünke" }], 'metadata' => { :total_pages => 10, :next_page => 2 }, 'errors' => ["Oh", "My", "God"] }.to_json] }
          stub.post("/users") { |env| [200, {}, { 'data' => { :name => "George Michael Bluth" }, 'metadata' => { :foo => "bar" }, 'errors' => ["Yes", "Sir"] }.to_json] }
        end
      end

      spawn_model :User do
        uses_api api
      end
    end

    it "handles metadata on a collection" do
      @users = User.all
      @users.metadata[:total_pages].should == 10
    end

    it "handles error data on a collection" do
      @users = User.all
      @users.errors.length.should == 3
    end

    it "handles metadata on a resource" do
      @user = User.create(:name => "George Michael Bluth")
      @user.metadata[:foo].should == "bar"
    end

    it "handles error data on a resource" do
      @user = User.create(:name => "George Michael Bluth")
      @user.response_errors.should == ["Yes", "Sir"]
    end
  end

  context "defining custom getters and setters" do
    before do
      api = Her::API.new
      api.setup :url => "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.get("/users/1") { |env| [200, {}, { :id => 1, :friends => ["Maeby", "GOB", "Anne"] }.to_json] }
          stub.get("/users/2") { |env| [200, {}, { :id => 1 }.to_json] }
        end
      end

      spawn_model :User do
        uses_api api
        belongs_to :organization

        def friends=(val)
          val = val.gsub("\r", "").split("\n").map { |friend| friend.gsub(/^\s*\*\s*/, "") } if val and val.is_a?(String)
          @attributes[:friends] = val
        end

        def friends
          @attributes[:friends].map { |friend| "* #{friend}" }.join("\n")
        end
      end
    end

    it "handles custom setters" do
      @user = User.find(1)
      @user.friends.should == "* Maeby\n* GOB\n* Anne"
      @user.instance_eval do
        @attributes[:friends] = ["Maeby", "GOB", "Anne"]
      end
    end

    it "handles custom getters" do
      @user = User.new
      @user.friends = "* George\n* Oscar\n* Lucille"
      @user.friends.should == "* George\n* Oscar\n* Lucille"
      @user.instance_eval do
        @attributes[:friends] = ["George", "Oscar", "Lucille"]
      end
    end
  end

  context "finding resources" do
    before do
      api = Her::API.new
      api.setup :url => "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.get("/users/1") { |env| [200, {}, { :id => 1, :age => 42 }.to_json] }
          stub.get("/users/2") { |env| [200, {}, { :id => 2, :age => 34 }.to_json] }
          stub.get("/users/3") { |env| [404, {}, nil] }
          stub.get("/users?id[]=1&id[]=2") { |env| [200, {}, [{ :id => 1, :age => 42 }, { :id => 2, :age => 34 }].to_json] }
          stub.get("/users?age=42&foo=bar") { |env| [200, {}, [{ :id => 3, :age => 42 }].to_json] }
          stub.get("/users?bad_request=true") { |env| [400, {}, { errors: ["bad request params"] }.to_json] }
          stub.get("/users?age=42") { |env| [200, {}, [{ :id => 1, :age => 42 }].to_json] }
          stub.get("/users?age=40") { |env| [200, {}, [{ :id => 1, :age => 40 }].to_json] }
        end
      end

      spawn_model :User do
        uses_api api
      end
    end

    it "handles finding by a single id" do
      @user = User.find(1)
      @user.id.should == 1
    end

    it "handles finding by multiple ids" do
      @users = User.find(1, 2)
      @users.should be_kind_of(Array)
      @users.length.should == 2
      @users[0].id.should == 1
      @users[1].id.should == 2
    end

    it "handles finding by an array of ids" do
      @users = User.find([1, 2])
      @users.should be_kind_of(Array)
      @users.length.should == 2
      @users[0].id.should == 1
      @users[1].id.should == 2
    end

    it "handles finding by an array of ids of length 1" do
      @users = User.find([1])
      @users.should be_kind_of(Array)
      @users.length.should == 1
      @users[0].id.should == 1
    end

    it "handles finding by an array id param of length 2" do
      @users = User.find(id: [1, 2])
      @users.should be_kind_of(Array)
      @users.length.should == 2
      @users[0].id.should == 1
      @users[1].id.should == 2
    end

    it 'handles finding with id parameter as an array' do
      @users = User.where(id: [1, 2])
      @users.should be_kind_of(Array)
      @users.length.should == 2
      @users[0].id.should == 1
      @users[1].id.should == 2
    end

    it "handles finding with other parameters" do
      @users = User.where(:age => 42, :foo => "bar").all
      @users.should be_kind_of(Array)
      @users.first.id.should == 3
    end

    it "handles finding with other parameters and scoped" do
      @users = User.scoped
      @users.where(:age => 42).should be_all { |u| u.age == 42 }
      @users.where(:age => 40).should be_all { |u| u.age == 40 }
    end

    it "throws when a given resource does not exist" do
      expect { User.find(3) }.to raise_error(Her::Errors::RecordNotFound, /User returned a 404/)
    end

    it "throws when accessing collection of a resource that does not exist" do
      @users = User.where(bad_request: true).all
      expect { @users.first }.to raise_error(Her::Errors::ResponseError, "Cannot access collection, Request returned an error")
    end
  end

  describe :find_by do
    before do
      api = Her::API.new
      api.setup :url => "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.get("/users/1") { |env| [200, {}, { :id => 1, :age => 42 }.to_json] }
        end
      end

      spawn_model :User do
        uses_api api
      end
    end

    it "supports the same basic behavior of find with an id" do
      expect(User.find_by(id: 1).id).to eq 1
    end
  end

  describe :first do
    before do
      api = Her::API.new
      api.setup :url => "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.get("/users/1") { |env| [200, {}, { :id => 1, :age => 42 }.to_json] }
          stub.get("/users/2") { |env| [404, {}, nil] }
          stub.get("/users/3") { |env| [410, {}, nil] }
          stub.get("/users/8") { |env| [401, {}, nil] }
          stub.get("/users/4?age=42&foo=bar") { |env| [200, {}, { :id => 4, :age => 42 }.to_json] }
          stub.get("/users?age=50&color=blue") { |env| [200, {}, [{ :id => 5, :age => 50, :color => 'blue' }].to_json] }
          stub.get("/users?id[]=6&id[]=7") { |env| [200, {}, [{ :id => 6 }].to_json] }
        end
      end

      spawn_model :User do
        uses_api api
      end
    end

    it "supports the same basic behavior of find with an id" do
      expect(User.where(id: 1).first.id).to eq 1
    end

    it "returns nil when a given resource returns 404" do
      expect(User.where(id: 2).first).to be_nil
    end

    it "returns nil when a given resource returns 410" do
      expect(User.where(id: 3).first).to be_nil
    end

    it "raises on any other 4xx" do
      expect { User.where(id: 8).first }.to raise_error(Her::Errors::ResponseError, /returned a 401/)
    end

    it "handles finding with an id AND other parameters" do
      expect(User.where(:id => 4, :age => 42, :foo => "bar").first.id).to eq 4
    end

    it "handles finding with other parameters" do
      expect(User.where(:age => 50, :color => "blue").first.id).to eq 5
    end

    it "accepts multiple id values" do
      expect(User.where(id: [6, 7]).first.id).to eq 6
    end
  end

  context "building resources" do
    context "when request_new_object_on_build is not set (default)" do
      before do
        spawn_model("Foo::User")
      end

      it "builds a new resource without requesting it" do
        Foo::User.should_not_receive(:request)
        @new_user = Foo::User.build(:fullname => "Tobias Fünke")
        @new_user.new?.should be_truthy
        @new_user.fullname.should == "Tobias Fünke"
      end
    end

    context "when request_new_object_on_build is set" do
      before do
        Her::API.setup :url => "https://api.example.com" do |builder|
          builder.use Her::Middleware::FirstLevelParseJSON
          builder.use Faraday::Request::UrlEncoded
          builder.adapter :test do |stub|
            stub.get("/users/new") { |env| ok! :id => nil, :fullname => params(env)[:fullname], :email => "tobias@bluthcompany.com" }
          end
        end

        spawn_model("Foo::User") { request_new_object_on_build true }
      end

      it "requests a new resource" do
        Foo::User.should_receive(:request).once.and_call_original
        @new_user = Foo::User.build(:fullname => "Tobias Fünke")
        @new_user.new?.should be_truthy
        @new_user.fullname.should == "Tobias Fünke"
        @new_user.email.should == "tobias@bluthcompany.com"
      end
    end
  end

  context "creating resources" do
    before do
      Her::API.setup :url => "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.post("/users") { |env| [200, {}, { :id => 1, :fullname => Faraday::Utils.parse_query(env[:body])['fullname'], :email => Faraday::Utils.parse_query(env[:body])['email'] }.to_json] }
          stub.post("/companies") { |env| [422, {}, { :errors => { :name => ["is required", "must be alphabetical"], :birthday => ['is required'] } }.to_json] }
        end
      end

      spawn_model "Foo::User"
      spawn_model "Foo::Company"
    end

    it "handle one-line resource creation" do
      @user = Foo::User.create(:fullname => "Tobias Fünke", :email => "tobias@bluth.com")
      @user.id.should == 1
      @user.fullname.should == "Tobias Fünke"
      @user.email.should == "tobias@bluth.com"
    end

    it "handle resource creation through Model.new + #save" do
      @user = Foo::User.new(:fullname => "Tobias Fünke")
      @user.save.should be true
      @user.fullname.should == "Tobias Fünke"
    end

    it "handle resource creation through Model.new + #save!" do
      @user = Foo::User.new(:fullname => "Tobias Fünke")
      @user.save!.should be true
      @user.fullname.should == "Tobias Fünke"
    end

    it "returns false when #save gets errors" do
      @company = Foo::Company.new
      @company.save.should be false
    end

    it "raises RecordInvalid when #save! gets errors" do
      @company = Foo::Company.new
      expect { @company.save! }.to raise_error Her::Errors::RecordInvalid, "Remote validation of Foo::Company failed with a 422: name is required, must be alphabetical. birthday is required"
    end

    it "contains 1 copy of any error message when the server responds with validation errors" do
      @company = Foo::Company.new
      @company.save
      @company.save
      expect(@company.errors.messages).to include :name => ['is required', 'must be alphabetical']
    end

    it "don't overwrite data if response is empty" do
      @company = Foo::Company.new(:name => 'Company Inc.')
      @company.save.should be false
      @company.name.should == "Company Inc."
    end
  end

  context "updating resources" do
    before do
      Her::API.setup :url => "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.get("/users/1") { |env| [200, {}, { :id => 1, :fullname => "Tobias Fünke" }.to_json] }
          stub.put("/users/1") { |env| [200, {}, { :id => 1, :fullname => "Lindsay Fünke" }.to_json] }
        end
      end

      spawn_model "Foo::User"
    end

    it "handle resource data update without saving it" do
      @user = Foo::User.find(1)
      @user.fullname.should == "Tobias Fünke"
      @user.fullname = "Kittie Sanchez"
      @user.fullname.should == "Kittie Sanchez"
    end

    it "handle resource update through the .update class method" do
      @user = Foo::User.save_existing(1, { :fullname => "Lindsay Fünke" })
      @user.fullname.should == "Lindsay Fünke"
    end

    it "handle resource update through #save on an existing resource" do
      @user = Foo::User.find(1)
      @user.fullname = "Lindsay Fünke"
      @user.save
      @user.fullname.should == "Lindsay Fünke"
    end
  end

  context "deleting resources" do
    describe "successful deletion requests" do
      before do
        Her::API.setup :url => "https://api.example.com" do |builder|
          builder.use Her::Middleware::FirstLevelParseJSON
          builder.use Faraday::Request::UrlEncoded
          builder.adapter :test do |stub|
            stub.get("/users/1") { |env| [200, {}, { :id => 1, :fullname => "Tobias Fünke", :active => true }.to_json] }
            stub.delete("/users/1") { |env| [200, {}, { :id => 1, :fullname => "Lindsay Fünke", :active => false }.to_json] }
          end
        end

        spawn_model "Foo::User"
      end

      it "handle resource deletion through the .destroy class method" do
        @user = Foo::User.destroy_existing(1)
        @user.active.should be_falsey
        @user.should be_destroyed
      end

      it "handle resource deletion through #destroy on an existing resource" do
        @user = Foo::User.find(1)
        @user.destroy
        @user.active.should be_falsey
        @user.should be_destroyed
      end
    end

    describe "failed deletion requests (400-space responses)" do
      before do
        Her::API.setup :url => "https://api.example.com" do |builder|
          builder.use Her::Middleware::FirstLevelParseJSON
          builder.use Faraday::Request::UrlEncoded
          builder.adapter :test do |stub|
            stub.get("/users/1") { |env| [200, {}, { :id => 1, :fullname => "Tobias Fünke", :active => true }.to_json] }
            stub.get("/users/2") { |env| [200, {}, { :id => 2, :fullname => "Tobias Fünke", :active => true }.to_json] }
            stub.get("/users/3") { |env| [200, {}, { :id => 3, :fullname => "Tobias Fünke", :active => true }.to_json] }
            stub.delete("/users/1") { |env| [404, {}, { :id => 1, :fullname => "Lindsay Fünke", :active => false }.to_json] }
            stub.delete("/users/2") { |env| [411, {}, { :id => 2, :fullname => "Lindsay Fünke", :active => false }.to_json] }
            stub.delete("/users/3") { |env| [422, {}, { :id => 3, :fullname => "Lindsay Fünke", :active => false }.to_json] }
          end
        end

        spawn_model "Foo::User"
      end

      it "throws RecordNotFound exceptions for .destroy class method when a 404 is returned" do
        expect { Foo::User.destroy_existing(1) }.to raise_error(Her::Errors::RecordNotFound, /Foo::User returned a 404/)
      end

      it "throws RecordInvalid exceptions for .destroy class method when a 409 is returned" do
        expect { Foo::User.destroy_existing(2) }.to raise_error(Her::Errors::ResponseError, /Foo::User returned a 411/)
      end

      it "throws RecordInvalid exceptions for .destroy class method when a 422 is returned" do
        expect { Foo::User.destroy_existing(3) }.to raise_error(Her::Errors::RecordInvalid, /Foo::User returned a 422/)
      end

      it "throws RecordNotFound exceptions for #destroy on an existing resource when a 404 is returned" do
        @user = Foo::User.find(1)
        expect { @user.destroy }.to raise_error(Her::Errors::RecordNotFound, /Foo::User returned a 404/)
      end

      it "throws RecordInvalid exceptions for #destroy on an existing resource when a 409 is returned" do
        @user = Foo::User.find(2)
        expect { @user.destroy }.to raise_error(Her::Errors::ResponseError, /Foo::User returned a 411/)
      end

      it "throws RecordInvalid exceptions for #destroy on an existing resource when a 422 is returned" do
        @user = Foo::User.find(3)
        expect { @user.destroy }.to raise_error(Her::Errors::RecordInvalid, /Foo::User returned a 422/)
      end
    end

    describe "failed deletion requests (500-space responses)" do
      before do
        Her::API.setup :url => "https://api.example.com" do |builder|
          builder.use Her::Middleware::FirstLevelParseJSON
          builder.use Faraday::Request::UrlEncoded
          builder.adapter :test do |stub|
            stub.get("/users/1") { |env| [200, {}, { :id => 1, :fullname => "Tobias Fünke", :active => true }.to_json] }
            stub.delete("/users/1") { |env| [500, {}, { :id => 1, :fullname => "Lindsay Fünke", :active => false }.to_json] }
          end
        end

        spawn_model "Foo::User"
      end

      it "handles resource deletion through the .destroy class method" do
        expect { Foo::User.destroy_existing(1) }.to raise_error(Her::Errors::RemoteServerError, /Foo::User returned a 500/)
      end

      it "handles resource deletion through #destroy on an existing resource" do
        @user = Foo::User.find(1)
        expect { @user.destroy }.to raise_error(Her::Errors::RemoteServerError, /Foo::User returned a 500/)
      end
    end
  end

  describe '.with_request_headers, #request_headers and #request_options' do
    before do
      @headers = {}
      Her::API.setup :url => "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.options[:timeout] = 100
        builder.adapter :test do |stub|
          stub.get("/users/1") { |env|
            @headers = env[:request_headers]
            @timeout = env[:request][:timeout]
            [200, {}, { :id => 1, :fullname => "Tobias Fünke", :active => true }.to_json]
          }
          stub.get("/users?active=true") { |env|
            @headers = env[:request_headers]
            @timeout = env[:request][:timeout]
            [200, {}, [{ :id => 1, :fullname => "Tobias Fünke", :active => true }].to_json]
          }
          stub.get("/users") { |env|
            @headers = env[:request_headers]
            @timeout = env[:request][:timeout]
            [200, {}, [{ :id => 1, :fullname => "Tobias Fünke", :active => true }].to_json]
          }
          stub.put("/users/1") { |env|
            @headers = env[:request_headers]
            @timeout = env[:request][:timeout]
            [200, {}, { :id => 1, :fullname => "Tobias Fünke", :active => true }.to_json]
          }
          stub.post("/users") { |env|
            @headers = env[:request_headers]
            @timeout = env[:request][:timeout]
            [200, {}, { :id => 1, :fullname => "Tobias Fünke", :active => true }.to_json]
          }
          stub.delete("/users/1") { |env|
            @headers = env[:request_headers]
            @timeout = env[:request][:timeout]
            [200, {}, nil]
          }
        end
      end

      spawn_model "Foo::User"
    end

    it "includes headers added via a relation chain" do
      user = Foo::User.where(active: true).with_request_headers("Authorization" => "Basic FooBar").all.first
      expect(@headers).to include "Authorization" => "Basic FooBar"
    end

    it "sets timeout added via a relation chain" do
      user = Foo::User.where(active: true).with_request_options(timeout: 1).all.first
      expect(@timeout).to eq 1
    end

    it "includes headers added via start of a relation chain" do
      user = Foo::User.with_request_headers("Authorization" => "Basic FooBar").find(1)
      expect(@headers).to include "Authorization" => "Basic FooBar"
    end

    it "sets timeout added via start of a relation chain" do
      user = Foo::User.with_request_options(timeout: 2).find(1)
      expect(@timeout).to eq 2
    end

    it "includes headers added via start of a relation chain when creating" do
      user = Foo::User.with_request_headers("Authorization" => "Basic FooBar").create
      expect(@headers).to include "Authorization" => "Basic FooBar"
    end

    it "includes timeout added via start of a relation chain when creating" do
      user = Foo::User.with_request_options(timeout: 3).create
      expect(@timeout).to eq 3
    end

    it "includes headers added to an instance when saving" do
      user = Foo::User.find(1)
      user.request_headers = { "Authorization" => "Basic FooBar" }
      user.save
      expect(@headers).to include "Authorization" => "Basic FooBar"
    end

    it "includes headers added to an instance when destroying" do
      user = Foo::User.find(1)
      user.request_headers = { "Authorization" => "Basic FooBar" }
      user.destroy
      expect(@headers).to include "Authorization" => "Basic FooBar"
    end

    it "includes headers added when destroying existing" do
      Foo::User.destroy_existing(1, {}, { "Authorization" => "Basic FooBar" })
      expect(@headers).to include "Authorization" => "Basic FooBar"
    end

    it "includes timeout added when destroying existing" do
      Foo::User.destroy_existing(1, {}, {}, timeout: 4)
      expect(@timeout).to eq 4
    end

    it "includes headers added via start of a relation chain when saving existing" do
      user = Foo::User.save_existing(1, {}, { "Authorization" => "Basic FooBar" })
      expect(@headers).to include "Authorization" => "Basic FooBar"
    end

    it "includes timeout added via start of a relation chain when saving existing" do
      user = Foo::User.save_existing(1, {}, {}, timeout: 5)
      expect(@timeout).to eq 5
    end


    it "overrides the timeout when added to an existing model's request_options" do
      user = Foo::User.find(1)
      user.request_options = { timeout: 6 }
      user.save

      expect(@timeout).to eq 6
    end

    it "overrides the timeout when added to a new model's request_options" do
      user = Foo::User.new
      user.request_options = { timeout: 7 }
      user.save

      expect(@timeout).to eq 7
    end

    it "overrides the timeout when added to destroying a model with request_options" do
      user = Foo::User.find(1)
      user.request_options = { timeout: 8 }
      user.destroy

      expect(@timeout).to eq 8
    end

    it "does not remove timeout set up by the api" do
      user = Foo::User.find(1)
      user.destroy

      expect(@timeout).to eq 100
    end

    it "raises an exception when setting unimplemented options" do
      user = Foo::User.find(1)
      user.request_options = { not_implemented: 123, 500 => 'crazy' }

      expect { user.save }.to raise_error "options not implemented: not_implemented, 500"
    end
  end

  context 'customizing HTTP methods' do
    before do
      Her::API.setup :url => "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
      end
    end

    context 'create' do
      before do
        Her::API.default_api.connection.adapter :test do |stub|
          stub.put('/users') { |env| [200, {}, { :id => 1, :fullname => 'Tobias Fünke' }.to_json] }
        end
        spawn_model 'Foo::User' do
          attributes :fullname, :email
          method_for :create, 'PUT'
        end
      end

      context 'for top-level class' do
        it 'uses the custom method (PUT) instead of default method (POST)' do
          user = Foo::User.new(:fullname => 'Tobias Fünke')
          user.should be_new
          user.save.should be true
        end
      end

      context 'for children class' do
        before do
          class User < Foo::User; end
          @spawned_models << :User
        end

        it 'uses the custom method (PUT) instead of default method (POST)' do
          user = User.new(:fullname => 'Tobias Fünke')
          user.should be_new
          user.save.should be true
        end
      end
    end

    context 'update' do
      before do
        Her::API.default_api.connection.adapter :test do |stub|
          stub.get('/users/1') { |env| [200, {}, { :id => 1, :fullname => 'Lindsay Fünke' }.to_json] }
          stub.post('/users/1') { |env| [200, {}, { :id => 1, :fullname => 'Tobias Fünke' }.to_json] }
        end

        spawn_model 'Foo::User' do
          attributes :fullname, :email
          method_for :update, :post
        end
      end

      it 'uses the custom method (POST) instead of default method (PUT)' do
        user = Foo::User.find(1)
        user.fullname.should eq 'Lindsay Fünke'
        user.fullname = 'Toby Fünke'
        user.save
        user.fullname.should eq 'Tobias Fünke'
      end
    end
  end
end
