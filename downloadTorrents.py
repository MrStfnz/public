# Quick search for torrents, returns a the magnet link of a torrent. Can be further automated by feeding it a file:
# for i in $(cat movie_list.txt); do python3 tpbl.py $i; done
# which then in turn can be fed to transmission using transmission-remote

from tpblite import TPB
from sys import argv

from tpblite import CATEGORIES,ORDERS
# Create a TPB object with a domain name
t = TPB('https://tpb.party')

# Or create a TPB object with default domain if your provider doesn't block it :)
#t = TPB()

# Make sure to download in the category VIDEO.HD_MOVIES, and not porn
# To print all available categories, use the classmethod printOptions
#CATEGORIES.printOptions()
# Or just a subset of categories, like VIDEO
#CATEGORIES.VIDEO.printOptions()
# Similarly for the sort order
#ORDERS.printOptions()

if len(argv) > 1:
    searchme = "".join(argv[1:])
    torrents = t.search(searchme, category=CATEGORIES.VIDEO.HD_MOVIES)

#Add some filtering to not download trash torrents
torrent = torrents.getBestTorrent(min_seeds=3, min_filesize='500 MiB', max_filesize='8 GiB')

if len(torrents) == 0:
    print("Torrent not found:", searchme)
print(torrent.magnetlink)
