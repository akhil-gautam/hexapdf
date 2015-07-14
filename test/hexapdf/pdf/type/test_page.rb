# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/pdf/document'
require 'hexapdf/pdf/type/page'

describe HexaPDF::PDF::Type::Page do
  before do
    @doc = HexaPDF::PDF::Document.new
  end

  describe "[]" do
    before do
      @root = @doc.add(Type: :Pages)
      @kid = @doc.add(Type: :Pages, Parent: @root)
      @page = @doc.add(Type: :Page, Parent: @kid)
    end

    it "works normal for non-inheritable fields" do
      assert_equal(:Page, @page[:Type])
      assert_nil(@page[:Dur])
    end

    it "automatically retrieves inherited values" do
      @root[:MediaBox] = :media
      assert_equal(:media, @page[:MediaBox])

      @root[:Resources] = :root_res
      @kid[:Resources] = :res
      assert_equal(:res, @page[:Resources])

      @page[:CropBox] = :cropbox
      assert_equal(:cropbox, @page[:CropBox])

      @kid[:Rotate] = :kid_rotate
      assert_equal(:kid_rotate, @page[:Rotate])
      @kid.delete(:Rotate)
      assert_equal(0, @page[:Rotate])
    end
  end

  describe "validation" do
    it "fails if a required inheritable field is not set" do
      root = @doc.add(Type: :Pages)
      page = @doc.add(Type: :Page, Parent: root)
      message = ''
      refute(page.validate {|m, _| message = m})
      assert_match(/inheritable.*MediaBox/i, message)
    end
  end

  describe "contents" do
    it "returns the contents of a single content stream" do
      page = @doc.pages.add_page
      page[:Contents] = @doc.wrap({}, stream: 'q 10 w Q')
      assert_equal('q 10 w Q', page.contents)
    end

    it "returns the concatenated contents of multiple content stream" do
      page = @doc.pages.add_page
      page[:Contents] = [@doc.wrap({}, stream: 'q 10'), @doc.wrap({}, stream: 'w Q')]
      assert_equal('q 10 w Q', page.contents)
    end
  end

  describe "contents=" do
    it "creates a content stream if none already exist" do
      page = @doc.pages.add_page
      page.contents = 'test'
      assert_equal('test', page[:Contents].stream)
    end

    it "reuses an existing content stream" do
      page = @doc.pages.add_page
      page[:Contents] = content = @doc.wrap({}, stream: 'q 10 w Q')
      page.contents = 'test'
      assert_equal(content, page[:Contents])
      assert_equal('test', content.stream)
    end

    it "reuses the first content stream and deletes the rest if more than one exist" do
      page = @doc.pages.add_page
      page[:Contents] = [content = @doc.add({}, stream: 'q 10 w Q'), @doc.add({}, stream: 'q Q')]
      page.contents = 'test'
      assert_equal(content, page[:Contents])
      assert_equal('test', content.stream)
    end
  end

  describe "process_contents" do
    it "parses the contents and processes it" do
      page = @doc.pages.add_page
      page[:Contents] = @doc.wrap({}, stream: 'q 10 w Q')
      renderer = TestHelper::OperatorRecorder.new
      page.process_contents(renderer) {|processor| processor.operators.clear}
      assert_equal([[:save_graphics_state, []], [:set_line_width, [10]], [:restore_graphics_state, []]],
                   renderer.operations)
    end
  end
end
