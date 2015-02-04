require 'rails_helper'
require_relative '../../scripts/pb_core_ingester'

describe 'Catalog' do

  before(:all) do
    # This is a test in its own right elsewhere.
    ingester = PBCoreIngester.new
    ingester.delete_all
    Dir['spec/fixtures/pbcore/clean-*.xml'].each do |pbcore|
      ingester.ingest(pbcore)
    end
  end  

  def expect_count(count)
    case count
    when 0
      expect(page).to have_text("No entries found")
    when 1
      expect(page).to have_text("1 entry found")
    else 
      expect(page).to have_text("1 - #{count} of #{count}")
    end
  end
  
  describe '#index' do
    
    it 'works' do
      visit '/catalog?search_field=all_fields&q=1234'
      expect(page.status_code).to eq(200)
      [
        'Gratuitous Explosions',
        'Series NOVA',
        'uncataloged 2000-01-01',
        '2000-01-01',
        'Best episode ever!'
      ].each do |field|
        expect(page).to have_text(field)
      end
      
      expect(page).to have_css("img[src='https://mlamedia01.wgbh.org/aapb/thumbnail/1234.jpg']")
    end
    
    describe 'facets' do
      [
        ['media_type','Sound',6],
        ['genre','Interview',3],
        ['asset_type','Segment',5],
        ['organization','WGBH',1],
        ['year','2000',1]
      ].each do |(facet,value,count)|
        url = "/catalog?f[#{facet}][]=#{value}"
        it "#{facet}=#{value}: #{count}\t#{url}" do
          visit url
          expect(page.status_code).to eq(200)
          expect_count(count)
        end
      end
    end
    
    describe 'fields' do
      [
        ['all_fields','Larry',2],
        ['title','Larry',1],
        ['contrib','Larry',1]
      ].each do |(constraint,value,count)|
        url = "/catalog?search_field=#{constraint}&q=#{value}"
        it "#{constraint}=#{value}: #{count}\t#{url}" do
          visit url
          expect(page.status_code).to eq(200)
          expect_count(count)
        end
      end
    end
    
  end
  
  describe '#show' do
    
    it 'contains expected data' do
      visit '/catalog/1234'
      expect(page.status_code).to eq(200)
      [
        'Gratuitous Explosions',
        'Series NOVA', 
        '1234 5678',
        'Best episode ever!',
        'explosions -- gratuitious', 'musicals -- horror',
        'Album',
        'uncataloged 2000-01-01',
        'Horror', 'Musical',
        'Moving Image',
        'WGBH',
        'Copy Left: All rights reversed.',
        'Moving Image', '0:12:34', 'Moving Image',
        'Contributor Curly, Stooges, bald',
        'Creator Larry, Stooges, balding',
        'Publisher Moe, Stooges, hair' 
      ].each do |field|
        expect(page).to have_text(field)
      end
      
      expect(page).to have_css("img[src='https://mlamedia01.wgbh.org/aapb/thumbnail/1234.jpg']")
    end
    
  end

  describe 'all fixtures' do
      # TODO: figure out how to just use the before-all to set this.
      Dir['spec/fixtures/pbcore/clean-*.xml'].each do |file_name|
        id = PBCore.new(File.read(file_name)).id
        describe id do
          details_url = "/catalog/#{id.gsub('/','%2F')}" # Remember the URLs are tricky.
          it "details: #{details_url}" do
            visit details_url
            expect(page.status_code).to eq(200)
          end
          search_url = "/catalog?search_field=all_fields&q=#{id.gsub(/^(.*\W)?(\w+)$/,'\2')}"
          # because of tokenization, unless we strip the ID down we will get other matches.
          it "search: #{search_url}" do
            visit search_url
            expect(page.status_code).to eq(200)
            expect_count(1)
          end
        end
      end
    end
  
end