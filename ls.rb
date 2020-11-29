#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require 'etc'

def permission(perm)
  {
    '7': 'rwx',
    '6': 'rw-',
    '5': 'r-x',
    '4': 'r--',
    '2': '-w-',
    '1': '--x',
    '0': '---'
  }[perm]
end

# コマンドの設定
opt = OptionParser.new
program_config = {}
opt.on('-a') do |_v|
  program_config[:a] = true
end
opt.on('-r') do |_v|
  program_config[:r] = true
end
opt.on('-l') do |_v|
  program_config[:l] = true
end
opt.parse!(ARGV)

#-aオプション
files = if program_config[:a]
          Dir.glob('*', File::FNM_DOTMATCH).sort
        else
          Dir.glob('*').sort
        end

#-rオプション
files = files.reverse if program_config[:r]

#-lオプション
if program_config[:l]
  #トータル
  total_block = 0
  files.each do |file|
    fs = File::Stat.new(file)
    total_block += fs.blocks
  end
  puts "total #{total_block}"

  files.each do |file|
    # ディレクトリかファイルか
    fs = File::Stat.new(file)
    fs_mode = format('%#o', fs.mode)
    if fs_mode[1] == '4'
      print 'd'
    elsif fs_mode[1] == '1'
      print '-'
    end

    # パーミッション
    print permission(fs_mode[-3].intern)
    print permission(fs_mode[-2].intern)
    print permission(fs_mode[-1].intern)
    print ' '
    print format('%3d', fs.nlink) # ハードリンク数
    print format('%5s', Etc.getpwuid(fs.uid).name) # 所有者
    print format('%7s', Etc.getgrgid(fs.gid).name) # グループ
    print format('%6d', fs.size)  # ファイルサイズ 
    mtime = fs.mtime                  # 最終更新日
    print format('%3d', mtime.month)
    print format('%3d', mtime.day)
    print ' '
    print mtime.strftime('%H:%M')
    print ' '
    print file
    print "\n"
  end
else
  outputs = []
  files.each_slice(4) do |file|
    if file.length == 1
      file << nil << nil << nil
    elsif file.length == 2
      file << nil << nil
    elsif file.length == 3
      file << nil
    else
      file
    end
    outputs << file
  end

  outputs.transpose.each do |output|
    print format('%+-24s', output[0])
    print format('%+-24s', output[1])
    print format('%+-24s', output[2])
    print output[3]
    print "\n"
  end
end
