require File.expand_path('../../test_helper', File.dirname(__FILE__))

class CmsAdmin::PagesControllerTest < ActionController::TestCase

  def test_get_index
    get :index, :site_id => cms_sites(:default)
    assert_response :success
    assert assigns(:pages)
    assert_template :index
  end

  def test_get_index_with_no_pages
    Cms::Page.delete_all
    get :index, :site_id => cms_sites(:default)
    assert_response :redirect
    assert_redirected_to :action => :new
  end
  
  def test_get_index_with_category
    category = Cms::Category.create!(:label => 'Test Category', :categorized_type => 'Cms::Page')
    category.categorizations.create!(:categorized => cms_pages(:child))
    
    get :index, :site_id => cms_sites(:default), :category => category.label
    assert_response :success
    assert assigns(:pages)
    assert_equal 1, assigns(:pages).count
    assert assigns(:pages).first.categories.member? category
  end
  
  def test_get_index_with_category_invalid
    get :index, :site_id => cms_sites(:default), :category => 'invalid'
    assert_response :success
    assert assigns(:pages)
    assert_equal 0, assigns(:pages).count
  end
  
  def test_get_new
    site = cms_sites(:default)
    get :new, :site_id => site
    assert_response :success
    assert assigns(:page)
    assert_equal cms_layouts(:default), assigns(:page).layout
    assert_template :new
    assert_select "form[action=/cms-admin/sites/#{site.id}/pages]"
    assert_select "select[data-url=/cms-admin/sites/#{site.id}/pages/0/form_blocks]"
    assert_select "form[action='/cms-admin/sites/#{site.id}/files']"
  end

  def test_get_new_with_field_datetime
    cms_layouts(:default).update_attribute(:content, '{{cms:field:test_label:datetime}}')
    get :new, :site_id => cms_sites(:default)
    assert_select "input[type='text'][name='page[blocks_attributes][][content]'][class='date']"
    assert_select "input[type='hidden'][name='page[blocks_attributes][][label]'][value='test_label']"
  end

  def test_get_new_with_field_integer
    cms_layouts(:default).update_attribute(:content, '{{cms:field:test_label:integer}}')
    get :new, :site_id => cms_sites(:default)
    assert_select "input[type='number'][name='page[blocks_attributes][][content]']"
    assert_select "input[type='hidden'][name='page[blocks_attributes][][label]'][value='test_label']"
  end

  def test_get_new_with_field_string
    cms_layouts(:default).update_attribute(:content, '{{cms:field:test_label:string}}')
    get :new, :site_id => cms_sites(:default)
    assert_select "input[type='text'][name='page[blocks_attributes][][content]']"
    assert_select "input[type='hidden'][name='page[blocks_attributes][][label]'][value='test_label']"
  end

  def test_get_new_with_field_text
    cms_layouts(:default).update_attribute(:content, '{{cms:field:test_label:text}}')
    get :new, :site_id => cms_sites(:default)
    assert_select "textarea[name='page[blocks_attributes][][content]'][class='code']"
    assert_select "input[type='hidden'][name='page[blocks_attributes][][label]'][value='test_label']"
  end

  def test_get_new_with_page_datetime
    cms_layouts(:default).update_attribute(:content, '{{cms:page:test_label:datetime}}')
    get :new, :site_id => cms_sites(:default)
    assert_select "input[type='text'][name='page[blocks_attributes][][content]'][class='date']"
    assert_select "input[type='hidden'][name='page[blocks_attributes][][label]'][value='test_label']"
  end

  def test_get_new_with_page_integer
    cms_layouts(:default).update_attribute(:content, '{{cms:page:test_label:integer}}')
    get :new, :site_id => cms_sites(:default)
    assert_select "input[type='number'][name='page[blocks_attributes][][content]']"
    assert_select "input[type='hidden'][name='page[blocks_attributes][][label]'][value='test_label']"
  end

  def test_get_new_with_page_string
    cms_layouts(:default).update_attribute(:content, '{{cms:page:test_label:string}}')
    get :new, :site_id => cms_sites(:default)
    assert_select "input[type='text'][name='page[blocks_attributes][][content]']"
    assert_select "input[type='hidden'][name='page[blocks_attributes][][label]'][value='test_label']"
  end

  def test_get_new_with_page_text
    cms_layouts(:default).update_attribute(:content, '{{cms:page:test_label}}')
    get :new, :site_id => cms_sites(:default)
    assert_select "textarea[name='page[blocks_attributes][][content]'][class='code']"
    assert_select "input[type='hidden'][name='page[blocks_attributes][][label]'][value='test_label']"
  end

  def test_get_new_with_rich_page_text
    cms_layouts(:default).update_attribute(:content, '{{cms:page:test_label:rich_text}}')
    get :new, :site_id => cms_sites(:default)
    assert_select "textarea[name='page[blocks_attributes][][content]'][class='rich_text']"
    assert_select "input[type='hidden'][name='page[blocks_attributes][][label]'][value='test_label']"
  end

  def test_get_new_as_child_page
    get :new, :site_id => cms_sites(:default), :parent_id => cms_pages(:default)
    assert_response :success
    assert assigns(:page)
    assert_equal cms_pages(:default), assigns(:page).parent
    assert_template :new
  end

  def test_get_edit
    page = cms_pages(:default)
    get :edit, :site_id => page.site, :id => page
    assert_response :success
    assert assigns(:page)
    assert_template :edit
    assert_select "form[action=/cms-admin/sites/#{page.site.id}/pages/#{page.id}]"
    assert_select "select[data-url=/cms-admin/sites/#{page.site.id}/pages/#{page.id}/form_blocks]"
    assert_select "form[action='/cms-admin/sites/#{page.site.id}/files?file[page_id]=#{page.id}']"
  end

  def test_get_edit_failure
    get :edit, :site_id => cms_sites(:default), :id => 'not_found'
    assert_response :redirect
    assert_redirected_to :action => :index
    assert_equal 'Page not found', flash[:error]
  end

  def test_get_edit_with_blank_layout
    page = cms_pages(:default)
    page.update_attribute(:layout_id, nil)
    get :edit, :site_id => page.site, :id => page
    assert_response :success
    assert assigns(:page)
    assert assigns(:page).layout
  end
  
  def test_creation
    assert_difference 'Cms::Page.count' do
      assert_difference 'Cms::Block.count', 2 do
        post :create, :site_id => cms_sites(:default), :page => {
          :label          => 'Test Page',
          :slug           => 'test-page',
          :parent_id      => cms_pages(:default).id,
          :layout_id      => cms_layouts(:default).id,
          :blocks_attributes => [
            { :label    => 'default_page_text',
              :content  => 'content content' },
            { :label    => 'default_field_text',
              :content  => 'title content' }
          ]
        }, :commit => 'Create Page'
        assert_response :redirect
        page = Cms::Page.last
        assert_equal cms_sites(:default), page.site
        assert_redirected_to :action => :edit, :id => page
        assert_equal 'Page created', flash[:notice]
      end
    end
  end
  
  def test_creation_failure
    assert_no_difference ['Cms::Page.count', 'Cms::Block.count'] do
      post :create, :site_id => cms_sites(:default), :page => {
        :layout_id => cms_layouts(:default).id,
        :blocks_attributes => [
          { :label    => 'default_page_text',
            :content  => 'content content' },
          { :label    => 'default_field_text',
            :content  => 'title content' }
        ]
      }
      assert_response :success
      page = assigns(:page)
      assert_equal 2, page.blocks.size
      assert_equal ['content content', 'title content'], page.blocks.collect{|b| b.content}
      assert_template :new
      assert_equal 'Failed to create page', flash[:error]
    end
  end

  def test_update
    page = cms_pages(:default)
    assert_no_difference 'Cms::Block.count' do
      put :update, :site_id => page.site, :id => page, :page => {
        :label => 'Updated Label'
      }
      page.reload
      assert_response :redirect
      assert_redirected_to :action => :edit, :id => page
      assert_equal 'Page updated', flash[:notice]
      assert_equal 'Updated Label', page.label
    end
  end
  
  def test_update_with_layout_change
    page = cms_pages(:default)
    assert_difference 'Cms::Block.count', 2 do
      put :update, :site_id => page.site, :id => page, :page => {
        :label      => 'Updated Label',
        :layout_id  => cms_layouts(:nested).id,
        :blocks_attributes => [
          { :label    => 'content',
            :content  => 'new_page_text_content' },
          { :label    => 'header',
            :content  => 'new_page_string_content' }
        ]
      }
      page.reload
      assert_response :redirect
      assert_redirected_to :action => :edit, :id => page
      assert_equal 'Page updated', flash[:notice]
      assert_equal 'Updated Label', page.label
      assert_equal ['content', 'default_field_text', 'default_page_text', 'header'], page.blocks.collect{|b| b.label}
    end
  end

  def test_update_failure
    put :update, :site_id => cms_sites(:default), :id => cms_pages(:default), :page => {
      :label => ''
    }
    assert_response :success
    assert_template :edit
    assert assigns(:page)
    assert_equal 'Failed to update page', flash[:error]
  end

  def test_destroy
    assert_difference 'Cms::Page.count', -2 do
      assert_difference 'Cms::Block.count', -2 do
        delete :destroy, :site_id => cms_sites(:default), :id => cms_pages(:default)
        assert_response :redirect
        assert_redirected_to :action => :index
        assert_equal 'Page deleted', flash[:notice]
      end
    end
  end

  def test_get_form_blocks
    site = cms_sites(:default)
    xhr :get, :form_blocks, :site_id => site, :id => cms_pages(:default), :layout_id => cms_layouts(:nested).id
    assert_response :success
    assert assigns(:page)
    assert_equal 2, assigns(:page).tags.size
    assert_template :form_blocks

    xhr :get, :form_blocks, :site_id => site, :id => cms_pages(:default), :layout_id => cms_layouts(:default).id
    assert_response :success
    assert assigns(:page)
    assert_equal 4, assigns(:page).tags.size
    assert_template :form_blocks
  end

  def test_get_form_blocks_for_new_page
    xhr :get, :form_blocks, :site_id => cms_sites(:default), :id => 0, :layout_id => cms_layouts(:default).id
    assert_response :success
    assert assigns(:page)
    assert_equal 3, assigns(:page).tags.size
    assert_template :form_blocks
  end

  def test_creation_preview
    assert_no_difference 'Cms::Page.count' do
      post :create, :site_id => cms_sites(:default), :preview => 'Preview', :page => {
        :label      => 'Test Page',
        :slug       => 'test-page',
        :parent_id  => cms_pages(:default).id,
        :layout_id  => cms_layouts(:default).id,
        :blocks_attributes => [
          { :label    => 'default_page_text',
            :content  => 'preview content' }
        ]
      }
      assert_response :success
      assert_match /preview content/, response.body
    end
  end

  def test_update_preview
    page = cms_pages(:default)
    assert_no_difference 'Cms::Page.count' do
      put :update, :site_id => page.site, :preview => 'Preview', :id => page, :page => {
        :label => 'Updated Label',
        :blocks_attributes => [
          { :label    => 'default_page_text',
            :content  => 'preview content',
            :id       => cms_blocks(:default_page_text).id}
        ]
      }
      assert_response :success
      assert_match /preview content/, response.body
      page.reload
      assert_not_equal 'Updated Label', page.label
    end
  end

  def test_get_new_with_no_layout
    Cms::Layout.destroy_all
    get :new, :site_id => cms_sites(:default)
    assert_response :redirect
    assert_redirected_to new_cms_admin_site_layout_path(cms_sites(:default))
    assert_equal 'No Layouts found. Please create one.', flash[:error]
  end

  def test_get_edit_with_no_layout
    Cms::Layout.destroy_all
    page = cms_pages(:default)
    get :edit, :site_id => page.site, :id => page
    assert_response :redirect
    assert_redirected_to new_cms_admin_site_layout_path(page.site)
    assert_equal 'No Layouts found. Please create one.', flash[:error]
  end

  def test_get_toggle_branch
    page = cms_pages(:default)
    get :toggle_branch, :site_id => page.site, :id => page, :format => :js
    assert_response :success
    assert_equal [page.id.to_s], session[:cms_page_tree]

    get :toggle_branch, :site_id => page.site, :id => page, :format => :js
    assert_response :success
    assert_equal [], session[:cms_page_tree]
  end

  def test_reorder
    page_one = cms_pages(:child)
    page_two = cms_sites(:default).pages.create!(
      :parent => cms_pages(:default),
      :layout => cms_layouts(:default),
      :label  => 'test',
      :slug   => 'test'
    )
    assert_equal 0, page_one.position
    assert_equal 1, page_two.position

    post :reorder, :site_id => cms_sites(:default), :cms_page => [page_two.id, page_one.id]
    assert_response :success
    page_one.reload
    page_two.reload

    assert_equal 1, page_one.position
    assert_equal 0, page_two.position
  end

end