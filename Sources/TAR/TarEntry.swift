// Copyright (c) 2023 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import Foundation

/// Represents an entry from the TAR container.
public struct TarEntry: ContainerEntry {

    public var info: TarEntryInfo

    /**
     Entry's data (`nil` if entry is a directory, data isn't available or is set as the file URL).

     - Note: Accessing setter of this property causes `info.size` to be updated as well so it remains equal to
     `data.count`. If `data` is set to be `nil` then `info.size` is set to zero.
     */
    public var data: Data? {
        didSet {
            self.info.size = self.data?.count ?? 0
        }
    }
	
	/**
	 Entry's URL (`nil` by default and only used if `data` is `nil`).
	 */
	public var file: URL?

    /**
     Initializes the entry with its info and data. The stored `info.size` will also be updated to be equal to
     `data.count`. If `data` is `nil` then `info.size` will be set to zero.

     - Parameter info: Information about entry.
     - Parameter data: Entry's data; `nil` if entry is a directory or data isn't available.
     */
    public init(info: TarEntryInfo, data: Data?) {
        self.info = info
        self.info.size = data?.count ?? 0
        self.data = data
    }
	
	/**
	 Initializes the entry with its info and file URL.  If `data` is `nil` then  we will check for `file`.

	 - Parameter info: Information about entry.
	 - Parameter file: Entry's URL, `nil` if set in data Data.
	 */
	public init(info: TarEntryInfo, file: URL?) {
		self.info = info
		self.file = file
	}

}
