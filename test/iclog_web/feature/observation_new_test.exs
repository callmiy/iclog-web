defmodule IclogWeb.Feature.ObservationNewTest do
  use Iclog.FeatureCase

  alias Iclog.Observable.Observation
  alias Iclog.Observable.ObservationMeta

  @comment_name "new-observation-comment"
  @comment_error_id "new-observation-comment-error-id"
  @comment_text "Some comment"

  @submit_btn_name "new-observation-submit-btn"
  @reset_btn_name "new-observation-reset-btn"

  @new_title_name "new-observation-meta-title"
  @new_title_error_id "new-observation-meta-title-error-id"
  @title_text "Some title"

  @intro_name "new-observation-meta-intro"
  @intro_text "Some intro"

  @new_meta_dismiss_icon_class_name "observationNewMetaDismiss"
  @reveal_meta_icon_id "reveal-new-meta-form-icon"
  @new_created_alert_id "new-observation-created-info"

  @tag :integration
  # @tag :no_headless
  test "Create observable with new meta", _meta do
    navigate_to "/#/observations/new"
    assert visible_text({:class, "global-title"}) == "OBSERVABLES"
    assert visible_text({:class, "page-title"}) == "Observations"

    # submit and reset buttons are disabled
    submit_btn = find_element(:name, @submit_btn_name)
    refute element_enabled?(submit_btn)

    reset_btn = find_element(:name, @reset_btn_name)
    refute element_enabled?(reset_btn)

    # An icon to dismiss new meta form controls is invisible on page
    refute element?(:class, @new_meta_dismiss_icon_class_name)

    # The controls themselves are invisible
    refute element?(:name, @new_title_name)
    refute element?(:name, @intro_name)

    # when user clicks on "+" icon at end of title field, form controls to fill
    # in meta details (i.e. title and intro fields) are revealed
    find_element(:id, @reveal_meta_icon_id) |> click()

    # The icon to dismiss the new meta form controls is displayed
    # with a text "New Meta"
    meta_dismiss_icon = find_element(:class, @new_meta_dismiss_icon_class_name)
    assert visible_text(meta_dismiss_icon) == "New Meta"

    # And form controls for creating observation metas should now be revealed
    title_control = find_element(:name, @new_title_name)
    intro_control = find_element(:name, @intro_name)
    comment_control = find_element(:name, @comment_name)

    # The reveal new meta icon is now invisible on the page
    # (RuntimeError) stale element reference: element is not attached to the page document
    refute element?(:id, @reveal_meta_icon_id)

    control_validate_string_lenght(%{
      field: title_control,
      invalid_text: "so",
      string_len: 3,
      error_id: @new_title_error_id,
      valid_text: @title_text
    })

    # Reset btn is enabled
    assert element_enabled?(reset_btn)

    control_validate_string_lenght(%{
      field: comment_control,
      invalid_text: "so",
      string_len: 3,
      error_id: @comment_error_id,
      valid_text: @comment_text
    })

    # When reset button is clicked
    click(reset_btn)

    # reset button is disabled
    refute wait_for_condition(false, &element_enabled?/1, [reset_btn])

    # and all the fields are cleared
    assert_controls_empty([title_control, comment_control])

    # When user completes form with valid data
    fill_field title_control, @title_text
    fill_field intro_control, @intro_text
    fill_field comment_control, @comment_text

    # submit btn is enabled
    assert element_enabled?(submit_btn)

    # and no alert showing that observation created
    refute element?(:id, @new_created_alert_id)

    # When submit button is clicked
    click(submit_btn)

    # and an observation, with its meta, is created
    assert wait_for_condition(
      true,
      fn() ->
          Kernel.match?(
            [%Observation{id: _, observation_meta: %ObservationMeta{id: _}}],
            Observation.list(:with_meta)
          )
      end,
      []
    )

    # and all the fields are cleared
    assert_controls_empty([title_control, comment_control, intro_control])

    # and there is an alert showing observation created
    assert element?(:id, @new_created_alert_id)
  end

  @tag :integration
  # @tag :no_headless
  test "Create observable with existing meta", _meta do
    insert(:observation_meta, %{title: @title_text})
    assert 0 == length Observation.list(:with_meta)

    navigate_to "/#/observations/new"

    title_control = find_element(:id, "select-meta-input")
    control_validate_string_lenght(:no_valid_text, %{
      field: title_control,
      invalid_text: "so",
      string_len: 3,
      error_id: "select-meta-input-error-id",
      error_text: "Type more than 3 chars to trigger autocomplete!"
    })

    complete_title_via_auto_complete title_control

    # Reset btn is enabled
    reset_btn = find_element(:name, @reset_btn_name)
    assert element_enabled?(reset_btn)

    comment_control = find_element(:name, @comment_name)
    control_validate_string_lenght(%{
      field: comment_control,
      invalid_text: "so",
      string_len: 3,
      error_id: @comment_error_id,
      valid_text: @comment_text
    })

    # When reset button is clicked
    click(reset_btn)


    # reset button is disabled
    refute wait_for_condition(false, &element_enabled?/1, [reset_btn])

    # and all the fields are cleared
    assert_controls_empty([title_control, comment_control])

    # When user completes form with valid data
    complete_title_via_auto_complete title_control
    fill_field comment_control, @comment_text

    # submit btn is enabled
    submit_btn = find_element(:name, @submit_btn_name)
    assert element_enabled?(submit_btn)

    refute element?(:id, @new_created_alert_id)

    # When submit button is clicked
    click(submit_btn)
    # and an observation, with its meta, is created
    assert wait_for_condition(
      true,
      fn() ->
          1 == length Observation.list(:with_meta)
      end,
      []
    )

    # and all the fields are cleared
    assert_controls_empty([title_control, comment_control])
    assert element?(:id, @new_created_alert_id)
  end

  defp complete_title_via_auto_complete(control) do
    # Autocomplete menu is not yet revealed
    refute element? :class, "autocompleteAutocompleteItem"

    # When a at least 3 characters have been entered into the title field
    fill_field control, ""
    type_text "som", 2

    # Autocomplete menu is revealed
    auto_complete = find_element :class, "autocompleteAutocompleteItem"

    # When auto complete item is clicked
    click auto_complete

    # Title field then contains the text in the auto complete item
    assert wait_for_condition(
      true,
      fn() -> attribute_value(control, "value") == @title_text end,
      []
    )

    # Autocomplete menu is no longer visible
    refute element? :class, "autocompleteAutocompleteItem"
  end
end