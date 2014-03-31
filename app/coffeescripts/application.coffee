App = Ember.Application.create
  Router: Ember.Router.extend
    root: Ember.Route.extend
      route: '/'

      app: Ember.Route.extend
        route: '/'
        connectOutlets: ->
          App.router.get("applicationController").connectOutlet "visualizations", "visualizations"
window.App = App

#-------------------------
# View Helpers
#-------------------------
App.viewHelpers = {}
App.viewHelpers.vis_width = 300
App.viewHelpers.formError = (msg) ->
  $("#form_error").html(msg).show('fast')
App.viewHelpers.clearFormError = ->
  $("#form_error").hide('fast')
App.viewHelpers.slide_in_vis = ->
  setTimeout (->
    $(".vis").last().animate({"margin-left":0}, 200, 'linear', ->
      $(this).css("z-index", 50)
    )
  ), 1

#-------------------------
# MODELS
#-------------------------
App.model = {}
App.model.IncomeVis = Ember.Object.extend
  id: null
  title: ""
  cents_per_year: 0
  seconds_per_cent: 0
  day_total_cents: 0
  year_total_cents: 0
  hours_worked_per_week: 40
  interval: null
  paper: null
  day_total_display: (()->
    (@get("day_total_cents")/100).formatMoney 2
  ).property("day_total_cents")
  year_total_display: (()->
    (@get("year_total_cents")/100).formatMoney 2
  ).property("day_total_cents")
  hourly_wage_display: (()->
    (@get("cents_per_year") / (@get("hours_worked_per_week") * 52) / 100).formatMoney 2
  ).property("cents_per_year")
  yearly_wage_display: (()->
    (@get("cents_per_year") / 100).formatMoney 2
  ).property("cents_per_year")
  cent_time_display: (()->
    Math.round(@get("seconds_per_cent") * 10000)/10000 + " seconds"
  ).property("cents_per_year")
  cent_working_time_display: (()->
    cpy = @get("cents_per_year")
    wspy = @get("hours_worked_per_week") * 52 * 60 * 60
    Math.round(wspy/cpy * 10000)/10000 + " seconds"
  ).property("cents_per_year")


#-------------------------
# VIEWS
#-------------------------
App.ApplicationView = Ember.View.extend
  templateName: "application"
  elementId: "wrapper_all"

App.VisualizationsView = Ember.View.extend
  templateName: "visualizations"
  tagName: ''

#-------------------------
# CONTROLLERS
#-------------------------
App.ApplicationController = Ember.Controller.extend
  show_info: ->
    $("#info").fadeIn()
  hide_info: ->
    $("#info").fadeOut()

App.VisualizationsController = Ember.ArrayController.extend
  content: []
  show_pennies: true
  new_vis: (ctx, input_wage, input_hours, input_pay_type, title)->
    that = this
    App.viewHelpers.clearFormError()
    input_wage ?= Number($("input[name=wage]").val().replace(/,/g,''))
    input_hours ?= Number($("input[name=hours]").val())
    input_pay_type ?= $("input[name=wageType]:checked").val()
    unless input_wage
      return App.viewHelpers.formError("Not a valid wage.")
    unless input_hours
      return App.viewHelpers.formError("Not a valid hours/week.")
    if input_pay_type == "hourly"
      hourly_cents = input_wage * 100
      cpy = input_hours * 52 * hourly_cents
    else
      cpy = input_wage * 100

    cps = cpy / App.Seconds_in_a_year
    spc = 1 / cps
    # date crap
    now = new Date()
    day_start = new Date(now.getFullYear(), now.getMonth(), now.getDate())
    year_start = new Date(now.getFullYear(),0,0)
    sec_since_year_start = (now - year_start) / 1000
    sec_since_day_start = (now - day_start) / 1000
    vis = App.model.IncomeVis.create
      id: GUID()
      cents_per_year: cpy
      seconds_per_cent: spc
      hours_worked_per_week: input_hours
      day_total_cents: Math.round(sec_since_day_start * cps)
      year_total_cents: Math.round(sec_since_year_start * cps)
      title: title || "&nbsp;"
    vis.set "interval",
      interval: window.setInterval( (()->
        paper = vis.get "paper"
        sel = "##{vis.get("id")} .paper"
        unless paper
          vis.set "paper", Raphael($(sel)[0], '100%', '100%')
        if App.router.get("visualizationsController").get("show_pennies")
          paper = vis.get "paper"
          cx = Math.random() * ($(sel).width() - 40) + 20
          circle = paper.circle cx, -20, 10
          circle.attr("fill", "#E6A183");
          circle.attr("stroke", "#9C573F")
          circle.animate {
            cy: 2000
            },
            4000,
            'linear',
            () ->
             this.remove

        vis.set "day_total_cents", vis.get("day_total_cents")+1
        vis.set "year_total_cents", vis.get("year_total_cents")+1
      ), spc * 1000)
    @pushObject(vis)
    App.viewHelpers.slide_in_vis()
    @recalculate_vis_wrapper_dimensions()

  close: (e) ->
    @get("content").find (item, index, content) ->
      if item.get("id") is e["context"]
        window.clearInterval item.get("interval")
        $($(".vis")[index]).css("z-index", 40).animate({"margin-left":-250}, 200, 'linear', ->
          content.removeAt index
        )
        return true
    @recalculate_vis_wrapper_dimensions()

  recalculate_vis_wrapper_dimensions: ->
    $("#visualizations_wrapper .scroll_wrapper>.ember-view").css "width", (@get("content").length * App.viewHelpers.vis_width + 10)

  # PRESETS
  romney_2010: ->
    @new_vis null, 21700000, 40, "yearly", "Mitt Romney 2010"
  barack_michelle_2010: ->
    @new_vis null, 1728096, 40, "yearly", "Barack & Michelle Obama 2010"
  average_foxconn: ->
    @new_vis null, 4320, 60, "yearly", "Average Foxconn worker"
  us_minimum: ->
    @new_vis null, 7.25, 40, "hourly", "USA minimum wage full time"

#-------------------------
# HELPERS
#-------------------------
App.Seconds_in_a_day = 60 * 60 * 24
App.Seconds_in_a_year = App.Seconds_in_a_day * 365

#-------------------------
# ON DOM LOAD
#-------------------------
$ ->
  App.initialize()
