defmodule JaSerializer.JsonApiSpec.CompoundDocumentTest do
  use ExUnit.Case

  @expected """
  {
    "jsonapi": {"version": "1.0"},
    "data": [{
      "type": "articles",
      "id": "1",
      "attributes": {
        "title": "JSON API paints my bikeshed!"
      },
      "links": {
        "self": "/articles/1"
      },
      "relationships": {
        "author": {
          "links": {
            "related": "/articles/1/author"
          },
          "data": { "type": "people", "id": "9" }
        },
        "comments": {
          "links": {
            "related": "/articles/1/comments"
          },
          "data": [
            { "type": "comments", "id": "5" },
            { "type": "comments", "id": "12" }
          ]
        }
      }
    }],
    "included": [{
      "type": "people",
      "id": "9",
      "attributes": {
        "first-name": "Dan",
        "last-name": "Gebhardt",
        "twitter": "dgeb"
      },
      "links": {
        "self": "/people/9"
      }
    }, {
      "type": "comments",
      "id": "5",
      "attributes": {
        "body": "First!"
      },
      "links": {
        "self": "/comments/5"
      }
    }, {
      "type": "comments",
      "id": "12",
      "attributes": {
        "body": "I like XML better"
      },
      "links": {
        "self": "/comments/12"
      }
    }]
  }
  """

  defmodule ArticleSerializer do
    use JaSerializer
    alias JaSerializer.JsonApiSpec.CompoundDocumentTest.PersonSerializer
    alias JaSerializer.JsonApiSpec.CompoundDocumentTest.CommentSerializer

    def type, do: "articles"
    location "/articles/:id"
    attributes [:title]
    has_many :comments,
      link: "/articles/:id/comments",
      include: CommentSerializer
    has_one :author,
      link: "/articles/:id/author",
      include: PersonSerializer
  end

  defmodule PersonSerializer do
    use JaSerializer
    def type, do: "people"
    location "/people/:id"
    attributes [:first_name, :last_name, :twitter]
  end

  defmodule CommentSerializer do
    use JaSerializer
    def type, do: "comments"
    location "/comments/:id"
    attributes [:body]
  end

  test "it serializes properly" do
    author = %TestModel.Person{
      id: 9,
      first_name: "Dan",
      last_name: "Gebhardt",
      twitter: "dgeb"
    }

    c1 = %TestModel.Comment{
      id: 5,
      body: "First!"
    }

    c2 = %TestModel.Comment{
      id: 12,
      body: "I like XML better"
    }

    article = %TestModel.Article{
      id: 1,
      title: "JSON API paints my bikeshed!",
      author: author,
      comments: [c1, c2]
    }

    results = [article]
              |> ArticleSerializer.format
              |> Poison.encode!
              |> Poison.decode!(keys: :atoms)

    expected = Poison.decode!(@expected, keys: :atoms)

    assert results[:data] == expected[:data]
    assert results[:included] == expected[:included]
    assert results == expected
  end
end
