require 'spec_helper'

describe Her::ErrorCollection do

  let(:metadata) { { :name => 'Testname' } }
  let(:errors) { { :name => ['not_present'] } }

  describe "#new" do
    context "without parameters" do
      subject { Her::ErrorCollection.new }

      it "raises upon access" do
        expect { subject[0] }.to raise_error(Her::Errors::ResponseError, "Cannot access collection, Request returned an error")
        expect { subject.last }.to raise_error(Her::Errors::ResponseError, "Cannot access collection, Request returned an error")
      end

      its(:metadata) { should eq({}) }
      its(:errors) { should eq({}) }
    end

    context "with parameters" do
      subject { Her::ErrorCollection.new(metadata, errors) }

      it "raises upon access" do
        expect { subject[0] }.to raise_error(Her::Errors::ResponseError, "Cannot access collection, Request returned an error")
        expect { subject.last }.to raise_error(Her::Errors::ResponseError, "Cannot access collection, Request returned an error")
      end

      its(:metadata) { should eq({ :name => 'Testname' }) }
      its(:errors) { should eq({ :name => ['not_present'] }) }
    end
  end
end
