# Description:
#   Github issue link looks for #nnn and links to that issue for your default
#   repo. Eg. "Hey guys check out #273"
#   Defaults to issues in HUBOT_GITHUB_REPO, unless a repo is specified Eg. "Hey guys, check out awesome-repo#273"
#
# Dependencies:
#   "githubot": "0.4.x"
#
# Configuration:
#   HUBOT_GITHUB_REPO
#   HUBOT_GITHUB_TOKEN
#   HUBOT_GITHUB_USER
#
# Commands:
#   #nnn - link to GitHub issue nnn for HUBOT_GITHUB_REPO project
#   repo#nnn - link to GitHub issue nnn for repo project
#   user/repo#nnn - link to GitHub issue nnn for user/repo project
#
# Derived from https://github.com/github/hubot-scripts/blob/master/src/scripts/github-issue-link.coffee


_ = require 'lodash'


usersToIgnore = /github|hubot|rufus/gi

module.exports = (robot) ->
  github = require('githubot') robot

  robot.hear /((\S*|^)?#(\d+)).*/, (msg) ->
    return if msg.message.user.name.match usersToIgnore

    # find all repo#issue pairs in the message string
    r = /((\S*|^)?#(\d+))/g
    matches = []
    while match = r.exec msg.message then do (match) ->

      issueNumber = match[3]
      return if isNaN issueNumber

      repo = if match[2] is undefined
        github.qualified_repo process.env.HUBOT_GITHUB_REPO
      else github.qualified_repo match[2]

      matches.push repo: repo, issueNumber: issueNumber

    # remove duplicates
    matches = _.uniq matches, (obj) -> obj.repo + String obj.issueNumber

    messagesToSend = []

    # asynchronously hit github api for issue titles, then publish a single
    # message on completion
    doneCallingApi = _.after matches.length, ->
      # sort by repo and issue number
      messagesToSend.sort (a, b) ->
        if a.repo > b.repo then return 1
        if a.repo < b.repo then return -1
        return a.issueNumber - b.issueNumber

      msg.send _.pluck(messagesToSend, 'message').join '\n'

    for match in matches then do (match) ->
      issuePath = "#{match.repo}/issues/#{match.issueNumber}"

      github.get "https://api.github.com/repos/#{issuePath}", (issue) ->
        issueUrl = "https://github.com/#{issuePath}"
        issueStr = "##{match.issueNumber}"
        if match.repo isnt 'vidahealth/webserver'
          issueStr = match.repo + issueStr
        messagesToSend.push {
          message: "*#{issueStr}* — #{issue.title} #{issueUrl}"
          repo: match.repo
          issueNumber: match.issueNumber
        }
        doneCallingApi()
