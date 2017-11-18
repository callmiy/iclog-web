defmodule IclogWeb.Feature.ObservationListTest do
  @moduledoc false

  use Iclog.FeatureCase

  alias Iclog.Observable.Observation
  alias Iclog.Observable.ObservationMeta

  @format_str_regex ".*{WDshort} {0D}/{Mshort}/{YY}.*{h12}:{m} {AM}.*"

  @tag :integration
  # @tag :no_headless
  test "List observations", _meta do
    [%Observation{
      id: id_first,
      comment: comment_first,
      inserted_at: inserted_at_first_,
      observation_meta: %ObservationMeta{title: title_first}
    } | obs] = insert_list(11, :observation)

    %Observation{
      id: id_last,
      comment: comment_last,
      inserted_at: inserted_at_last_,
      observation_meta: %ObservationMeta{title: title_last}
    } = List.last obs

    navigate_to "/#/"

    {inserted_at_first, _} = timex_ecto_date_to_local_tz(inserted_at_first_)
    _inserted_at_first_regex = Timex.format!(inserted_at_first, @format_str_regex)
    comment_first_regex = ".*#{comment_first}.*"
    title_first_regex = ".*#{title_first}.*"

    {inserted_at_last, _} = timex_ecto_date_to_local_tz(inserted_at_last_)
    inserted_at_last_regex = Timex.format!(inserted_at_last, @format_str_regex)
    comment_last_regex = ".*#{comment_last}.*"
    title_last_regex = ".*#{title_last}.*"

    # Last comment to be inserted is visible in page
    assert wait_for_condition(
      true,
      fn() ->
        visible_in_page?(Regex.compile! comment_last_regex)
      end,
      []
    )

    # But first comment is not visible
    refute visible_in_page?(Regex.compile! comment_first_regex)

    # Last Inserted at datetime is visible on page
    assert visible_in_page?(Regex.compile! inserted_at_last_regex, "s")

    # Last title is visible in page
    assert visible_in_page?(Regex.compile! title_last_regex)

    # But first title is not visible in page
    refute visible_in_page?(Regex.compile! title_first_regex)

    # link to go to detail page of last observation is present in page
    assert element?(:css, "a[href$='/observations/#{id_last}']")

    # But link to go to detail page of first observation is not present in page
    refute element?(:css, "a[href$='/observations/#{id_first}']")

    # There are a total of 10 such links
    assert length(
        find_all_elements(:class, "observation-list-to-observation-detail-link")
      ) == 10

    # text indicating pagination is visible in page
    assert visible_in_page?(~r/.*Page 1 of 2.*/)

    # previous pagination arrow is disabled
    previous_page_arrow = find_element :id, "pagination-previous-page-arrow"
    refute element_enabled?(previous_page_arrow)

    # when next pagination arrow is clicked
    next_page_arrow = find_element :id, "pagination-next-page-arrow"
    click next_page_arrow

  end
end