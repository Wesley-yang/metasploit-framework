module UserServlet

  def self.api_path
    '/api/v1/users'
  end

  def self.api_path_with_id
    "#{UserServlet.api_path}/?:id?"
  end

  def self.registered(app)
    app.get UserServlet.api_path_with_id, &get_user
    app.post UserServlet.api_path, &report_user
    app.put UserServlet.api_path_with_id, &update_user
    app.delete UserServlet.api_path, &delete_user
  end

  #######
  private
  #######

  def self.get_user
    lambda {
      warden.authenticate!(scope: :admin_api)
      begin
        sanitized_params = sanitize_params(params)
        data = get_db.users(sanitized_params)
        set_json_data_response(response: data)
      rescue => e
        print_error_and_create_response(error: e, message: 'There was an error retrieving users:', code: 500)
      end
    }
  end

  def self.report_user
    lambda {
      warden.authenticate!(scope: :admin_api)
      job = lambda { |opts|
        get_db.report_user(opts)
      }
      exec_report_job(request, &job)
    }
  end

  def self.update_user
    lambda {
      warden.authenticate!(scope: :admin_api)
      begin
        opts = parse_json_request(request, false)
        tmp_params = sanitize_params(params)
        opts[:id] = tmp_params[:id] if tmp_params[:id]
        data = get_db.update_user(opts)
        # Only return the single object if the id parameter is present
        data = data.first if !sanitized_params[:id].nil? && data.count == 1
        set_json_data_response(response: data)
      rescue => e
        print_error_and_create_response(error: e, message: 'There was an error creating the user:', code: 500)
      end
    }
  end

  def self.delete_user
    lambda {
      warden.authenticate!(scope: :admin_api)
      begin
        opts = parse_json_request(request, false)
        data = get_db.delete_user(opts)
        set_json_data_response(response: data)
      rescue => e
        print_error_and_create_response(error: e, message: 'There was an error deleting the users:', code: 500)
      end
    }
  end

end