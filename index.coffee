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
    hostname: process.env.KATANA_HOSTNAME or "katana.*"
    slack: process.env.HUBOT_SLACK_TOKEN or false


slack_attachement = (msg, hostname, build) ->
    state_text = states[build.results_text][1]
    try
        msg.robot.emit 'slack.attachment',
            message: msg.message
            content:
                mrkdwn_in: ["text", "fields", "author_name"]
                color: states[build.results_text][0]
                author_name: "<http://#{hostname}|Katana>"
                author_icon: "https://oc.unity3d.com/index.php/s/2738VI33nxJ98Bn/download"
                text: ""
                fields: [
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
                ]
    catch error
        msg.robot.logger.debug(error)

plain = (msg, hostname, build) ->
    state_text = states[build.results_text][1]
    try
        message = "Builder: #{build.builderFriendlyName}\n" +
                "Number: #{build.number}\n" +
                "Status: #{state_text}\n" +
                "Slave: #{build.slave_friendly_name}\n"
        msg.send message
    catch error
        msg.robot.logger.debug(error)

send_katana_msg = (msg, hostname, build) ->
    if options.slack != false
        plain(msg, hostname, build)
    else
        slack_attachement(msg, hostname, build)

module.exports = (robot) ->
    robot.hear ///(#{options.hostname})\/projects\/.+\/builders\/(.+)\/builds\/(\d+)\?.*///i, (msg) ->
        hostname = msg.match[1]
        builder = msg.match[2]
        number = msg.match[3]
        url = "http://#{hostname}/json/builders/#{builder}/builds/#{number}"
        msg.http(url)
        .get() (err, res, body) ->
            try
                json = JSON.parse(body)
                if json.results_text == ""
                    json.results_text = "running"

                send_katana_msg(msg, hostname, json)

            catch error
                msg.robot.logger.debug(error)


    robot.hear ///(#{options.hostname})\/projects\/Unity\/builders\?(.+)///i, (msg) ->
        hostname = msg.match[1]
        params = msg.match[2]
        builder = "proj0-ABuildVerification"
        url = "http://#{hostname}/json/projects/Unity/#{builder}/?{#params}"

        msg.http(url)
        .get() (err, res, body) ->
            try
                json = JSON.parse(body)

                send_katana_msg(msg, hostname, json.latestBuild)
            catch error
                msg.robot.logger.debug(error)