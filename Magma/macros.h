#ifndef __MAGMA_MACROS_H
#define __MAGMA_MACROS_H

// Convenience macros
#define sqlite3_bind_text(stmt, index, text) sqlite3_bind_text(stmt, index, text, strlen(text), SQLITE_STATIC)

// Unused
#define DatabaseFailedToLoadNotification @"com.pixelomer.magma/DatabaseFailedToLoad"

#endif