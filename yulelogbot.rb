#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'rubygems'
require 'chatterbot/dsl'
require 'twitter-text'

FIRE = Twitter::Unicode::U1F525

#http://emojipedia.org/collision-symbol/
#http://www.iemoji.com/view/emoji/258/objects/father-christmas
#http://www.iemoji.com/view/emoji/552/symbols/black-large-square
BLACK_SQUARE = Twitter::Unicode::U2B1B

#http://www.iemoji.com/view/emoji/553/symbols/white-large-square
WHITE_SQUARE = Twitter::Unicode::U2B1C

# http://www.iemoji.com/view/emoji/394/objects/alien-monster

# http://www.iemoji.com/view/emoji/259/objects/christmas-tree
#XMAS_TREE = Twitter::Unicode::U1F384

# http://www.iemoji.com/view/emoji/699/people/thought-balloon
SMOKE=Twitter::Unicode::U1F4AD

#http://www.iemoji.com/view/emoji/44/people/sparkles
SPARKLES=Twitter::Unicode::U2728

#http://www.iemoji.com/view/emoji/45/people/glowing-star
STAR=Twitter::Unicode::U1F31F

#http://www.iemoji.com/view/emoji/697/people/dizzy-symbol
DIZZY=Twitter::Unicode::U1F4AB

DECORATIONS = [SMOKE, SPARKLES, STAR, DIZZY]
DECORATION_CHANCE = 0.1
# no decoration if the fire isn't higher than 1
MIN_DECORATION_LEVEL = 1

WIDTH=12
HEIGHT=10
BORDER=2

EMITTER_WIDTH = 1
EMITTERS = (WIDTH-(BORDER*2))/EMITTER_WIDTH
FIRE_ROWS = 5

# max allowed difference between columns of fire
MAX_DIFF = 1

# max allowed level for fire
MAX_LEVEL = 5


#
# this is the script for the twitter bot yulelogbot
# generated on 2014-12-02 13:52:49 -0500
#

bot
bot.config.delete(:db_uri)

BASE_CHANGE_CHANCE = 0.5


day = Date.today.day
@do_shrink = false

if day < 20
  @grow_bump = 0.1
elsif day <= 25
  @grow_bump = 0.15
else
  puts "hey we're in cooldown mode"
  @do_shrink = true
  @grow_bump = 0.05
end

def generate(row)
  new_emitters = row.collect { |e|
    chance = BASE_CHANGE_CHANCE + ( (3-e).abs * 0.1)

    if @do_shrink == true
      if e == 0
        e
      else
        e = e + [0, 0, 0, 0, -1].sample
      end
      # if rand < chance
      #   opts = [0]
      #   #opts << 1 if e < MAX_LEVEL
      #   #opts = [-1]
      #   opts << -1 if e > 1
      #   e = e + opts.sample
      # end
    else
      acted = false
      if e < MAX_LEVEL
        chance = BASE_CHANGE_CHANCE + (e*0.1)
        do_grow = rand > chance - @grow_bump
        if do_grow
          e = e + 1
          acted = true
        end
      end
      
      if ! acted && e > 1
        #chance = 0.5
        chance = BASE_CHANGE_CHANCE - (e*0.05)
        if e == MAX_LEVEL
          chance = 0.2
        end
        do_shrink = rand > chance
        
        if do_shrink
          e = e - 1
        end
      end
    end
    e
  }
  new_emitters
end


def valid?(row)
  valid = true
  row.each_with_index { |e, idx|
    next if valid == false
    l = idx = 1
    r = idx + 1
    if l < 0
      l = row.length - 1
    end
    if r >= row.length
      r = 0
    end

    neighbors = [row[l] , row[r]].compact
    valid = neighbors.all? { |n| (n-e).abs <= MAX_DIFF }
  }
  valid
end

def update_fire
  emitters = generate(bot.config[:emitters].dup)
  1.upto(100) {
    if valid?(emitters)
      return emitters
      
    end
    emitters = generate(bot.config[:emitters].dup)
  }
  emitters
end


def render_fire
  emitters = bot.config[:emitters]
  # top
  base = [
          [BLACK_SQUARE] * WIDTH
         ]

  # guts
  FIRE_ROWS.downto(1) do |level|
    row = [BLACK_SQUARE] * BORDER

    emitters.each_with_index do |e, idx|
      sprite = nil
      if e >= level
        sprite = FIRE
      else
        sprite = WHITE_SQUARE          
      end

      if e > MIN_DECORATION_LEVEL && rand <= DECORATION_CHANCE && (e == level || e == level - 1)
        sprite = DECORATIONS.sample
      end
      
      row << [sprite] * EMITTER_WIDTH
    end

    
    row << [BLACK_SQUARE] * BORDER    

    base << row
  end

  # footer?

  base << [[BLACK_SQUARE] * WIDTH]

  
  base.collect { |r| r.join("")  }.join("\n")
end

@test_mode = false


if @test_mode
  while true
    bot.config[:emitters] ||= [1] * EMITTERS

    bot.config[:emitters] = update_fire

    system("clear")
    output = render_fire
    puts output
    sleep 0.5
  end

else
  bot.config[:emitters] ||= [1] * EMITTERS

  do_reset = false
  last_run = bot.config[:last_run] || 0

  # has it been more than 30 days? reset!
  if Time.now.to_i - last_run > 3600*24*30
    do_reset = true
  end
  
  if !do_reset && bot.config[:emitters].select { |val| val > 0 }.count == 0
    # if the fire went out last round, we're done! see you next year
  else
    bot.config[:last_run] = Time.now.to_i
    
    bot.config[:emitters] = update_fire
    puts bot.config[:emitters].inspect

    output = render_fire

    tweet output

    puts output
  end
end


