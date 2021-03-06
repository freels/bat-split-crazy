# BatSplitCrazy

by Matt Freels

A/B tests are awesome. Setting them up and keeping track of the results is not so awesome.

# Usage

in your models:

    define_variate_test :alt_layout do |t|
      t.start_date '2009-03-31 12:00'
      t.groups :control, :show_alt
    end

in where you want to use the test, say in a view:

    if user.test_variate :alt_layout
      # do something...
    else
      # do default
    end

it can also get more complicated. for example:

    define_variate_test :alt_layout do |t|
      t.start_date '2009-03-31 12:00'
      t.end_date '2009-04-07 12:00'
      t.qualifier :created_at # qualifier returns true if the models created_at method 
                              # returns a date after the test start date

      t.split_count 6
      t.modulo do |user|
        case user.id % 6             # this test can run simultaneously with
        when 0,1 then :control       # another test split with user.id % 2
        when 2,3 then :new_layout_1  # and not skew the results.
        when 4,5 then :new_layout_2
        end
      end
    end

`test_variate` returns either `nil` or the group symbol. The `:control` group is special, as `test_variate` returns `nil` if the modulo function returns `:control`.

you can also create reports:

    define_variate_test :alt_layout do |t|
      # snip...

      t.report do |test, report|
        # define report here...
      end
    end

for simple reports, supply a conforming AR connection.select_all result and you're done:

    t.report do |test, report|
      report.columns :clicks, :unique_users

      report.with_sql_results User.connection.select_all("
        select user_id % 2 as 'bucket', \
        count(*) as 'clicks', \
        count(distict user_id) as 'unique_users' \
        from click_events where created_at > '#{test.start_date.to_s :db}' \
        group by user_id % 2
      ")
    end

alternatively you can dig in:

    t.report do |test, report|
      report.columns :clicks, :logins
      
      click_results = User.connection.select_all("
        select user_id % 6 as 'bucket', count(*) as 'clicks' from click_events \
        where created_at > '#{test.start_date.to_s :db}' group by user_id % 6
      ")

      login_results = User.connection.select_all("
        select user_id % 6 as 'bucket', count(*) as 'logins' from login_events \
        where created_at > '#{test.start_date.to_s :db}' group by user_id % 6
      ")

      test.buckets.each do |name, vals| # name is a name defined earlier with t.groups
                                        # vals is an array for which the modulo function
                                        # returns name
        clicks = click_results.select{|r| vals.include? r['bucket'].to_i}.map{|r| r['clicks'].to_i}.sum
        logins = login_results.select{|r| vals.include? r['bucket'].to_i}.map{|r| r['logins'].to_i}.sum
        
        report.row name, clicks, logins # data order is the same as defined earlier with
                                        # report.columns. 
        # alternatively pass a hash:
        # report.row name, :clicks => clicks, :logins => logins
      end
    end

Copyright (c) 2009 Serious Business, released under the MIT license
