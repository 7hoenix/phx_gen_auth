Code.require_file("../../mix_helper.exs", __DIR__)

defmodule Mix.Tasks.Phx.Gen.AuthTest do
  use ExUnit.Case

  import MixHelper
  alias Mix.Tasks.Phx.Gen

  setup do
    Mix.Task.clear()
    :ok
  end

  defp in_tmp_auth_project(test, func) do
    in_tmp_project(test, fn ->
      File.mkdir_p!("lib/phx_gen_auth_web")
      File.mkdir_p!("test/support")
      File.touch!("test/support/conn_case.ex")
      File.write!("lib/phx_gen_auth_web/router.ex", routerfile_contents())

      func.()
    end)
  end

  test "generates auth logic", config do
    in_tmp_auth_project(config.test, fn ->
      Gen.Auth.run(~w(Accounts User users))

      assert_file("lib/phx_gen_auth/accounts.ex", fn file ->
        assert file =~ "defmodule PhxGenAuth.Accounts"
      end)

      assert_file("lib/phx_gen_auth/accounts/user_notifier.ex", fn file ->
        assert file =~ "defmodule PhxGenAuth.Accounts.UserNotifier"
        assert file =~ "def deliver_confirmation_instructions(user, url)"
      end)

      assert_file("lib/phx_gen_auth/accounts/user.ex", fn file ->
        assert file =~ "defmodule PhxGenAuth.Accounts.User"
        assert file =~ ~s|schema "users"|
      end)

      assert_file("lib/phx_gen_auth/accounts/user_token.ex", fn file ->
        assert file =~ "defmodule PhxGenAuth.Accounts.UserToken"
        assert file =~ ~s|schema "user_tokens"|
      end)

      assert [migration] = Path.wildcard("priv/repo/migrations/*_create_auth_tables.exs")

      assert_file(migration, fn file ->
        assert file =~ "create table(:users) do"
        assert file =~ "create table(:user_tokens) do"
      end)

      assert_file("test/phx_gen_auth/accounts_test.exs", fn file ->
        assert file =~ "defmodule PhxGenAuth.AccountsTest"
      end)

      assert_file("test/support/fixtures/accounts_fixtures.ex", fn file ->
        assert file =~ "defmodule PhxGenAuth.AccountsFixtures"
      end)

      assert_file("test/support/conn_case.ex", fn file ->
        assert file =~ "def register_and_login_user(%{conn: conn})"
        assert file =~ "def login_user(conn, user)"
      end)

      assert_file("lib/phx_gen_auth_web/controllers/user_auth.ex", fn file ->
        assert file =~ "defmodule PhxGenAuthWeb.UserAuth"
      end)

      assert_file("test/phx_gen_auth_web/controllers/user_auth_test.exs", fn file ->
        assert file =~ "defmodule PhxGenAuthWeb.UserAuthTest"
        assert file =~ "PhxGenAuthWeb.Endpoint.config("
      end)

      assert_file("lib/phx_gen_auth_web/views/user_confirmation_view.ex", fn file ->
        assert file =~ "defmodule PhxGenAuthWeb.UserConfirmationView"
      end)

      assert_file("lib/phx_gen_auth_web/views/user_registration_view.ex", fn file ->
        assert file =~ "defmodule PhxGenAuthWeb.UserRegistrationView"
      end)

      assert_file("lib/phx_gen_auth_web/views/user_reset_password_view.ex", fn file ->
        assert file =~ "defmodule PhxGenAuthWeb.UserResetPasswordView"
      end)

      assert_file("lib/phx_gen_auth_web/views/user_session_view.ex", fn file ->
        assert file =~ "defmodule PhxGenAuthWeb.UserSessionView"
      end)

      assert_file("lib/phx_gen_auth_web/views/user_settings_view.ex", fn file ->
        assert file =~ "defmodule PhxGenAuthWeb.UserSettingsView"
      end)

      assert_file("lib/phx_gen_auth_web/router.ex", fn file ->
        assert file =~ "import PhxGenAuthWeb.UserAuth"
        assert file =~ ~s|delete "/users/logout", UserSessionController, :delete|
      end)
    end)
  end

  # test "does not inject code if its already been injected"

  def routerfile_contents do
    """
    defmodule PhxGenAuthWeb.Router do
      use PhxGenAuthWeb, :router

      pipeline :browser do
        plug :accepts, ["html"]
        plug :fetch_session
        plug :fetch_flash
        plug :protect_from_forgery
        plug :put_secure_browser_headers
      end

      pipeline :api do
        plug :accepts, ["json"]
      end

      scope "/", PhxGenAuthWeb do
        pipe_through :browser

        get "/", PageController, :index
      end

      # Other scopes may use custom stacks.
      # scope "/api", DemoWeb do
      #   pipe_through :api
      # end
    end
    """
  end
end
