defmodule Ash.Test.Notifier.PubSubTest do
  @moduledoc false
  use ExUnit.Case, async: false

  defmodule PubSub do
    def broadcast(topic, event, notification) do
      send(
        Application.get_env(__MODULE__, :notifier_test_pid),
        {:broadcast, topic, event, notification}
      )
    end
  end

  defmodule Post do
    @moduledoc false
    use Ash.Resource,
      data_layer: Ash.DataLayer.Ets,
      notifiers: [
        Ash.Notifier.PubSub
      ]

    pub_sub do
      module PubSub
      prefix "post"

      publish :destroy, ["foo", :id]
      publish :update, ["foo", :id]
      publish :update, ["bar", :name], event: "name_change"
      publish :update_pkey, ["foo", :_pkey]
    end

    ets do
      private?(true)
    end

    actions do
      defaults [:create, :read, :update, :destroy]
      update :update_pkey
    end

    attributes do
      uuid_primary_key :id, writable?: true

      attribute :name, :string
    end
  end

  defmodule Registry do
    @moduledoc false
    use Ash.Registry

    entries do
      entry Post
    end
  end

  defmodule Api do
    use Ash.Api

    resources do
      registry Registry
    end
  end

  setup do
    Application.put_env(PubSub, :notifier_test_pid, self())

    :ok
  end

  test "publishing a message with a change value" do
    post =
      Post
      |> Ash.Changeset.new(%{})
      |> Api.create!()

    Api.destroy!(post)

    message = "post:foo:#{post.id}"
    assert_receive {:broadcast, ^message, "destroy", %Ash.Notifier.Notification{}}
  end

  test "from is the pid that sent the message" do
    post =
      Post
      |> Ash.Changeset.new(%{})
      |> Api.create!()

    Api.destroy!(post)

    message = "post:foo:#{post.id}"
    pid = self()
    assert_receive {:broadcast, ^message, "destroy", %Ash.Notifier.Notification{from: ^pid}}
  end

  test "notification_metadata is included" do
    post =
      Post
      |> Ash.Changeset.new(%{})
      |> Api.create!()

    Api.destroy!(post, notification_metadata: %{foo: :bar})

    message = "post:foo:#{post.id}"

    assert_receive {:broadcast, ^message, "destroy",
                    %Ash.Notifier.Notification{metadata: %{foo: :bar}}}
  end

  test "publishing a message with multiple matches/changes" do
    post =
      Post
      |> Ash.Changeset.new(%{name: "ted"})
      |> Api.create!()

    post
    |> Ash.Changeset.new(%{name: "joe"})
    |> Api.update!()

    message = "post:foo:#{post.id}"
    assert_receive {:broadcast, ^message, "update", %Ash.Notifier.Notification{}}

    message = "post:bar:joe"
    assert_receive {:broadcast, ^message, "name_change", %Ash.Notifier.Notification{}}
    message = "post:bar:ted"
    assert_receive {:broadcast, ^message, "name_change", %Ash.Notifier.Notification{}}
  end

  test "publishing a message with a pkey matcher" do
    post =
      Post
      |> Ash.Changeset.new(%{name: "ted"})
      |> Api.create!()

    new_id = Ash.UUID.generate()

    post
    |> Ash.Changeset.new(%{id: new_id})
    |> Api.update!(action: :update_pkey)

    message = "post:foo:#{post.id}"
    assert_receive {:broadcast, ^message, "update_pkey", %Ash.Notifier.Notification{}}

    message = "post:foo:#{new_id}"
    assert_receive {:broadcast, ^message, "update_pkey", %Ash.Notifier.Notification{}}
  end
end
