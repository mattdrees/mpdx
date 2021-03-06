require 'spec_helper'

describe TasksController do
  before(:each) do 
    @user = create(:user_with_account)
    sign_in(:user, @user)
    @account_list = @user.account_lists.first
  end

  def valid_attributes
    FactoryGirl.build(:task, account_list: @account_list).attributes.except('id', 'type', 'created_at', 'updated_at', 'account_list_id', 'activity_comments_count', 'completed_at')
  end

  describe "GET index" do
    it "assigns all tasks as @tasks" do
      task = @account_list.tasks.create! valid_attributes
      get :index, {}
      assigns(:overdue).should eq([task])
    end

    it "filters by tag" do
      task1 = @account_list.tasks.create! valid_attributes.merge(tag_list: 'foo')
      task2 = @account_list.tasks.create! valid_attributes.merge(tag_list: 'bar')
      get :index, filters: {tags: 'foo'}
      assigns(:overdue).should eq([task1])
    end
  end

  describe "GET new" do
    it "assigns a new task as @task" do
      get :new, {}
      assigns(:task).should be_a_new(Task)
    end
  end

  describe "GET edit" do
    it "assigns the requested task as @task" do
      task = @account_list.tasks.create! valid_attributes
      get :edit, {:id => task.to_param}
      assigns(:task).should eq(task)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new Task" do
        expect {
          post :create, {:task => valid_attributes}
        }.to change(@account_list.tasks, :count).by(1)
      end

      it "assigns a newly created task as @task" do
        post :create, {:task => valid_attributes}
        assigns(:task).should be_a(Task)
        assigns(:task).should be_persisted
      end

      it "redirects to the created task" do
        post :create, {:task => valid_attributes}
        response.should redirect_to(tasks_path)
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved task as @task" do
        # Trigger the behavior that occurs when invalid params are submitted
        Task.any_instance.stub(:save).and_return(false)
        post :create, {:task => {}}
        assigns(:task).should be_a_new(Task)
      end

      it "re-renders the 'new' template" do
        # Trigger the behavior that occurs when invalid params are submitted
        Task.any_instance.stub(:save).and_return(false)
        post :create, {:task => {}}
        response.should render_template("new")
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      it "updates the requested task" do
        task = @account_list.tasks.create! valid_attributes
        # Assuming there are no other tasks in the database, this
        # specifies that the Task created on the previous line
        # receives the :update_attributes message with whatever params are
        # submitted in the request.
        Task.any_instance.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, {:id => task.to_param, :task => {'these' => 'params'}}
      end

      it "assigns the requested task as @task" do
        task = @account_list.tasks.create! valid_attributes
        put :update, {:id => task.to_param, :task => valid_attributes}
        assigns(:task).should eq(task)
      end

      it "redirects to the task" do
        task = @account_list.tasks.create! valid_attributes
        put :update, {:id => task.to_param, :task => valid_attributes}
        response.should redirect_to(tasks_path)
      end
    end

    describe "with invalid params" do
      it "assigns the task as @task" do
        task = @account_list.tasks.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        Task.any_instance.stub(:save).and_return(false)
        put :update, {:id => task.to_param, :task => {}}
        assigns(:task).should eq(task)
      end

      it "re-renders the 'edit' template" do
        task = @account_list.tasks.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        Task.any_instance.stub(:save).and_return(false)
        put :update, {:id => task.to_param, :task => {}}
        response.should render_template("edit")
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested task" do
      task = @account_list.tasks.create! valid_attributes
      request.env['HTTP_REFERER'] = tasks_url
      expect {
        delete :destroy, {:id => task.to_param}
      }.to change(@account_list.tasks, :count).by(-1)
    end

    it "redirects to the tasks list" do
      task = @account_list.tasks.create! valid_attributes
      request.env['HTTP_REFERER'] = tasks_url
      delete :destroy, {:id => task.to_param}
      response.should redirect_to(request.env['HTTP_REFERER'])
    end
  end

end
