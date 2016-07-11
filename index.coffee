moment = require 'moment'

states = {
    success: ["#b6c9a6", "Success"],
    failure: ["#dc9696", "Failure"],
    exception: ["#baaeba", "Exception"],
    warnings: ["#fa3", "Warnings"],
    skipped: ["#CBDCE6", "Skipped"],
    dependency_failure: ["#f2c9c9", "Dependency failure"],
    not_rebuilt: ["#edf7dd", "Not rebuilt"],
    running: ["#c2317c", "Running"]
}

options =
    hostname: process.env.KATANA_HOSTNAME or "(staging-*)katana.*"
    slack: if process.env.HUBOT_SLACK_TOKEN.length > 0 then true else false
    date_format: 'MMMM Do YYYY, h:mm:ss a'


slack_attachement = (msg, hostname, build) ->
    state_text = states[build.results_text][1]
    try
        fields = [
            {
                title: "Builder",
                value: "<#{build.builder_url}|#{build.builderFriendlyName}>",
                short: "false"
            },
            {
                title: "Number",
                value: "<#{build.url.path}|#{build.number}>",
                short: "true"
            },
            {
                title: "Status",
                value: "#{state_text}",
                short: "true"
            },
            {
                title: "Slave",
                value: "<#{build.slave_url}|#{build.slave_friendly_name}>",
                short: "true"
            },
            {
                title: "Started",
                value: moment.utc(build.times[0] * 1000).format(options.date_format),
                short: "true"
            }
        ]

        if build.times.length > 1 and build.times[1] != null
            fields.push {
                title: "Finished",
                value: moment.utc(build.times[1] * 1000).format(options.date_format),
                short: "true"
            }

        msg.robot.emit 'slack.attachment',
            message: msg.message
            content:
                mrkdwn_in: ["text", "fields", "author_name"]
                color: states[build.results_text][0]
                author_name: "Katana"
                author_link: "http://#{hostname}"
                author_icon: "https://oc.unity3d.com/index.php/s/2738VI33nxJ98Bn/download"
                text: ""
                fields: fields
                fallback: plain_msg(msg, hostname, build)


    catch error
        msg.robot.logger.debug(error)

plain_msg = (msg, hostname, build) ->
    state_text = states[build.results_text][1]
    message = "Builder: #{build.builderFriendlyName}\n" +
            "Number: #{build.number}\n" +
            "Status: #{state_text}\n" +
            "Slave: #{build.slave_friendly_name}\n" +
            "Started: " + moment.utc(build.times[0] * 1000).format(options.date_format) + "\n"

    if build.times.length > 1 and build.times[1] != null
        message += "Finished: " + moment.utc(build.times[1] * 1000).format(options.date_format) + "\n"

    return message

plain = (msg, hostname, build) ->
    try
        msg.send(plain_msg(msg, hostname, build))
    catch error
        msg.robot.logger.debug(error)

send_katana_msg = (msg, hostname, build) ->
    if options.slack
        slack_attachement(msg, hostname, build)
    else
        plain(msg, hostname, build)

module.exports = (robot) ->
    robot.hear ///(http|https)://(#{options.hostname})\/projects\/.+\/builders\/(.+)\/builds\/(\d+)\?.*///i, (msg) ->
        scheme = msg.match[1]
        hostname = msg.match[2]
        builder = msg.match[4]
        number = msg.match[5]
        url = "#{scheme}://#{hostname}/json/builders/#{builder}/builds/#{number}"
        msg.http(url)
        .get() (err, res, body) ->
            try
                json = JSON.parse(body)
                if json.results_text == ""
                    json.results_text = "running"

                send_katana_msg(msg, hostname, json)

            catch error
                msg.robot.logger.debug(error)


    robot.hear ///(http|https)://(#{options.hostname})\/projects\/Unity\/builders\?(.+)///i, (msg) ->
        scheme = msg.match[1]
        hostname = msg.match[2]
        params = msg.match[4]
        builder = "proj0-ABuildVerification"
        url = "#{scheme}://#{hostname}/json/projects/Unity/#{builder}/?#{params}"
        msg.http(url)
        .get() (err, res, body) ->
            try
                json = JSON.parse(body)
                send_katana_msg(msg, hostname, json.latestBuild)
            catch error
                msg.robot.logger.debug(error)