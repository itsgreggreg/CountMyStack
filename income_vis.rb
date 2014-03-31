class IncomeVis < Sinatra::Base
  #register Barista::Integration::Sinatra

  # assets
  get "/stylesheets/application.css" do
    scss :'stylesheets/application'
  end

  get "/"  do
    erb :index
  end

end