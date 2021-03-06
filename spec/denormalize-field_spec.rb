require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

class Category < ActiveRecord::Base
  has_many :posts
end

class Post < ActiveRecord::Base
  belongs_to :category
  denormalizes category: :name
end

describe DenormalizeUpdater do
  let(:category) { Category.new(name: "News") }
  let(:post)     { Post.create(category: category) }

  it "syncs all records" do
    post.connection.execute("UPDATE posts set category_name = 'cool story';")
    in_sync_post = Post.create(category: category)
    Post.categories_out_of_sync.should == [post]
  end
end

describe "DenormalizeField" do
  let(:category) { Category.new(name: "News") }
  let(:post)     { Post.new(category: category) }

  it "denormalizes fields on save" do
    post.save!
    post.reload
    post.category_name.should == "News"
  end

  it "updates the denormalized field when the column changes" do
    post.save!
    category = Category.first
    category.name = "Sports"
    category.save!
    post.reload
    post.category_name.should == "Sports"
  end

  it "handles field values with quotes" do
    post.save!
    category = Category.first
    category.name = "Champion's League"
    category.save!
    post.reload
    post.category_name.should == "Champion's League"
  end

  it "handles nil associations" do
    post.category = nil
    expect { post.save! }.to_not raise_error
  end

  it "doesn't save the association unless the denormalized field has changed" do
    post.save!
    updated_at = post.updated_at
    category = Category.first
    Post.any_instance.expects(:update_attribute).never
    category.save!
    post.reload
    post.updated_at.should == updated_at
  end
end
