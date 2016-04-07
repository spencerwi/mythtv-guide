open Lwt
open Cohttp
open Cohttp_lwt
open Cohttp_lwt_unix
open Core
open Prelude


type program_recording_preferences = {
    status: string [@key "Status"] [@default ""];
    priority: string [@key "Priority"] [@default ""];
    startTs: string [@key "StartTs"] [@default ""];
    endTs: string [@key "EndTs"] [@default ""];
    recordId: string [@key "RecordId"] [@default ""];
    recGroup: string [@key "RecGroup"] [@default ""];
    playGroup: string [@key "PlayGroup"] [@default ""];
    recType: string [@key "RecType"] [@default ""];
    dupInType: string [@key "DupInType"] [@default ""];
    dupMethod: string [@key "DupMethod"] [@default ""];
    encoderId: string [@key "EncoderId"] [@default ""];
    profile: string [@key "Profile"] [@default ""];
} [@@deriving yojson { strict = false }];;

type program = {
    startTime: Time_Yojson_adapter.t [@key "StartTime"];
    endTime: Time_Yojson_adapter.t [@key "EndTime"];
    title: string [@key "Title"];
    subtitle: string [@key "SubTitle"];
    category: string [@key "Category"];
    catType: string [@key "CatType"];
    repeat: string [@key "Repeat"];
    recording: program_recording_preferences option [@key "Recording"] [@default None];
} [@@deriving yojson { strict = false }];;

type channel = {
    chanId: string [@key "ChanId"];
    chanNum: string [@key "ChanNum"];
    callSign: string [@key "CallSign"];
    iconURL: string [@key "IconURL"];
    channelName: string [@key "ChannelName"];
    programs: program list [@key "Programs"];
} [@@deriving yojson { strict = false }];;

type program_guide = {
    asOf: string [@key "AsOf"];
    count: string [@key "Count"];
    details: string [@key "Details"];
    startTime: Time_Yojson_adapter.t [@key "StartTime"];
    endTime: Time_Yojson_adapter.t [@key "EndTime"];
    startChanId: string [@key "StartChanId"];
    endChanId: string [@key "EndChanId"];
    numOfChannels: string [@key "NumOfChannels"];
    channels: channel list [@key "Channels"];
} [@@deriving yojson { strict = false }];;

type guide_response = {
    guide: program_guide [@key "ProgramGuide"];
} [@@deriving yojson { strict = false }];;

let get_guide (start_time: Core.Time.t) (end_time: Core.Time.t) :  [`Error of string | `Ok of program_guide ] Lwt.t  =
    let zone = Core.Time.Zone.utc in (* Don't adjust the time zone again *)
    let (start_str, end_str) = (
        Core.Time.format start_time "%Y-%m-%dT%H:%M:%S" ~zone,
        Core.Time.format end_time "%Y-%m-%dT%H:%M:%S" ~zone
    ) in
    let guide_url = Uri.of_string ("http://localhost:6544/Guide/GetProgramGuide?StartTime=" ^ start_str  ^ "&EndTime=" ^ end_str) in
    let headers = Cohttp.Header.of_list [("Accept", "application/json")] 
    in
    Client.get ~headers:headers guide_url >>= fun (response, responseBody) -> 
        responseBody |> Cohttp_lwt_body.to_string >|= fun stringBody -> 
            stringBody 
            |> (Core.Std.String.filter ~f:Core.Std.Char.is_print) 
            |> Yojson.Safe.from_string 
            |> guide_response_of_yojson
            |> (function | `Error err -> `Error err
                         | `Ok r -> `Ok r.guide)

