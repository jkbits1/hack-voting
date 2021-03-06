module State exposing (..)

import Event.State as Event
import Exts.RemoteData as RemoteData exposing (..)
import Firebase.Auth as Firebase
import Response exposing (..)
import Types exposing (..)


initialState : ( Model, Cmd Msg )
initialState =
    ( { auth = Loading
      , eventModel = Nothing
      }
    , Cmd.none
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Sub.map AuthResponse Firebase.authResponse
        , model.eventModel
            |> Maybe.map (Event.subscriptions >> Sub.map EventMsg)
            |> Maybe.withDefault Sub.none
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Authenticate ->
            ( { model | auth = Loading }
            , Firebase.authenticate ()
            )

        AuthResponse response ->
            let
                newModel =
                    { model | auth = response }
            in
                Event.initialState
                    |> mapModel (\eventModel -> { newModel | eventModel = Just eventModel })
                    |> mapCmd EventMsg

        EventMsg submsg ->
            case ( model.auth, model.eventModel ) of
                ( Success user, Just eventModel ) ->
                    Event.update user submsg eventModel
                        |> mapModel (\eventModel -> { model | eventModel = Just eventModel })
                        |> mapCmd EventMsg

                _ ->
                    ( model, Cmd.none )
