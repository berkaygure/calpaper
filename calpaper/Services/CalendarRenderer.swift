import AppKit

struct CalendarRenderer {
    let settings: CalendarSettings

    func render(month: CalendarMonth, screenSize: NSSize, scaleFactor: CGFloat = 2.0, todayEvents: [CalendarEvent] = []) -> NSImage {
        let pixelWidth = Int(screenSize.width * scaleFactor)
        let pixelHeight = Int(screenSize.height * scaleFactor)

        let bitmapRep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: pixelWidth,
            pixelsHigh: pixelHeight,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )!
        bitmapRep.size = screenSize

        let context = NSGraphicsContext(bitmapImageRep: bitmapRep)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context

        // Flip coordinate system so Y goes top-to-bottom
        let transform = NSAffineTransform()
        transform.translateX(by: 0, yBy: screenSize.height)
        transform.scaleX(by: 1, yBy: -1)
        transform.concat()

        // Fill right side (calendar) background
        settings.backgroundColor.setFill()
        NSBezierPath.fill(NSRect(origin: .zero, size: screenSize))

        // Draw left side with curved arc divider — calculated after layout so we
        // know where the grid starts; the actual call is below after gridOriginX is known.

        // --- Calculate sizes ---
        let gridScale = settings.calendarScale
        let gridWidth = screenSize.width * gridScale
        let cellSize = gridWidth / 7
        let gridHeight = cellSize * 7.5

        let captionFontName = settings.captionFontName
        let captionFont = NSFont(name: captionFontName, size: cellSize * 2.5)
            ?? NSFont(name: "\(captionFontName)-Bold", size: cellSize * 2.5)
            ?? NSFont.systemFont(ofSize: cellSize * 2.5, weight: .thin)
        let monthText = month.monthName
        let captionSize = measureText(monthText, font: captionFont)

        let dayNameFont = NSFont(name: captionFontName, size: cellSize * 1.0)
            ?? NSFont.systemFont(ofSize: cellSize * 1.0, weight: .light)
        let dayOfWeek = todayDayName()
        let dayNameSize = measureText(dayOfWeek, font: dayNameFont)

        // Today's events text
        let eventFont = NSFont.systemFont(ofSize: cellSize * 0.4, weight: .regular)
        let eventLineHeight = cellSize * 0.55
        let maxVisibleEvents = min(todayEvents.count, 5)
        let eventsHeight = maxVisibleEvents > 0 ? cellSize * 0.3 + CGFloat(maxVisibleEvents) * eventLineHeight : 0

        let captionBlockWidth = max(captionSize.width, dayNameSize.width)
        let gap = cellSize * 1.2
        let captionTextHeight = captionSize.height + cellSize * 0.05 + dayNameSize.height + eventsHeight

        let totalContentWidth = captionBlockWidth + gap + gridWidth
        let totalContentHeight = max(captionTextHeight, gridHeight)

        // Position content block
        let blockX = screenSize.width * settings.calendarPositionX - totalContentWidth / 2
        let blockY = screenSize.height * settings.calendarPositionY - totalContentHeight / 2

        let margin = cellSize * 0.5
        let clampedX = max(margin, min(blockX, screenSize.width - totalContentWidth - margin))
        let clampedY = max(margin, min(blockY, screenSize.height - totalContentHeight - margin))

        // --- Draw curved background (left half) — must be before text ---
        let gridOriginX = clampedX + captionBlockWidth + gap
        drawCurvedBackground(screenSize: screenSize, gridLeftEdge: gridOriginX)

        // --- Draw caption (left side) ---
        let captionX = clampedX
        let captionCenterY = clampedY + totalContentHeight / 2 - captionTextHeight / 2

        drawText(monthText, at: NSPoint(x: captionX, y: captionCenterY), font: captionFont, color: settings.textColor)
        let dayNameY = captionCenterY + captionSize.height + cellSize * 0.05
        drawText(dayOfWeek, at: NSPoint(x: captionX, y: dayNameY), font: dayNameFont, color: settings.highlightColor)

        // Draw today's events below day name
        if maxVisibleEvents > 0 {
            var eventY = dayNameY + dayNameSize.height + cellSize * 0.3
            let dotSize = cellSize * 0.15
            for i in 0..<maxVisibleEvents {
                let event = todayEvents[i]
                let dotColor = NSColor(hex: event.color)

                // Draw colored dot
                dotColor.setFill()
                NSBezierPath(ovalIn: NSRect(x: captionX, y: eventY + (eventLineHeight - dotSize) / 2, width: dotSize, height: dotSize)).fill()

                // Draw event title
                let titleX = captionX + dotSize + cellSize * 0.1
                let maxTitleWidth = captionBlockWidth - dotSize - cellSize * 0.1
                let title = truncateText(event.title, font: eventFont, maxWidth: maxTitleWidth)
                drawText(title, at: NSPoint(x: titleX, y: eventY), font: eventFont, color: settings.textColor.withAlphaComponent(0.8))

                eventY += eventLineHeight
            }
        }

        // --- Draw grid (right side) ---
        let gridOriginY = clampedY + totalContentHeight / 2 - gridHeight / 2

        var currentY = gridOriginY
        drawWeekdayHeaders(month: month, originX: gridOriginX, y: currentY, cellSize: cellSize)
        currentY += cellSize * 1.0

        drawDayGrid(month: month, originX: gridOriginX, startY: currentY, cellSize: cellSize)

        NSGraphicsContext.restoreGraphicsState()

        let image = NSImage(size: screenSize)
        image.addRepresentation(bitmapRep)
        return image
    }

    private func drawCurvedBackground(screenSize: NSSize, gridLeftEdge: CGFloat) {
        // The arc bulges into the calendar grid area for a natural overlap
        let curveDepth = screenSize.width * 0.06
        let splitX = gridLeftEdge - curveDepth * 0.5

        let path = NSBezierPath()
        path.move(to: NSPoint(x: 0, y: 0))
        path.line(to: NSPoint(x: splitX, y: 0))

        // Arc from bottom to top, bulging right
        path.curve(
            to: NSPoint(x: splitX, y: screenSize.height),
            controlPoint1: NSPoint(x: splitX + curveDepth * 2, y: screenSize.height * 0.33),
            controlPoint2: NSPoint(x: splitX + curveDepth * 2, y: screenSize.height * 0.66)
        )

        path.line(to: NSPoint(x: 0, y: screenSize.height))
        path.close()

        settings.panelColor.setFill()
        path.fill()
    }

    private func todayDayName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: Date())
    }

    private func drawWeekdayHeaders(month: CalendarMonth, originX: CGFloat, y: CGFloat, cellSize: CGFloat) {
        let weekdayFont = NSFont.systemFont(ofSize: cellSize * 0.28, weight: .medium)

        for (index, header) in month.weekdayHeaders.enumerated() {
            let strSize = measureText(header, font: weekdayFont)
            let x = originX + CGFloat(index) * cellSize + (cellSize - strSize.width) / 2
            drawText(header, at: NSPoint(x: x, y: y), font: weekdayFont, color: settings.weekdayColor)
        }
    }

    private func drawDayGrid(month: CalendarMonth, originX: CGFloat, startY: CGFloat, cellSize: CGFloat) {
        let dayFont = NSFont.systemFont(ofSize: cellSize * 0.35, weight: .regular)
        let todayFont = NSFont.systemFont(ofSize: cellSize * 0.35, weight: .bold)
        let isProgressMode = settings.displayMode == .progressBar
        let maxRadius = (cellSize - cellSize * 0.12) / 2
        let cornerRadius = maxRadius * settings.cellCornerRadius
        let cellPadding = cellSize * 0.06

        for (weekIndex, week) in month.weeks.enumerated() {
            for (dayIndex, day) in week.enumerated() {
                guard day.dayNumber > 0 else { continue }

                if settings.showOnlyCurrentMonth && !day.isCurrentMonth {
                    continue
                }

                let x = originX + CGFloat(dayIndex) * cellSize
                let y = startY + CGFloat(weekIndex) * cellSize

                let centerX = x + cellSize / 2
                let centerY = y + cellSize / 2

                let bgRect = NSRect(
                    x: x + cellPadding,
                    y: y + cellPadding,
                    width: cellSize - cellPadding * 2,
                    height: cellSize - cellPadding * 2
                )

                if day.isToday {
                    settings.highlightColor.setFill()
                    NSBezierPath(roundedRect: bgRect, xRadius: cornerRadius, yRadius: cornerRadius).fill()
                } else if isProgressMode && day.isPast && day.isCurrentMonth {
                    settings.pastDayColor.setFill()
                    NSBezierPath(roundedRect: bgRect, xRadius: cornerRadius, yRadius: cornerRadius).fill()
                } else if day.isCurrentMonth && !day.isPast {
                    settings.futureDayColor.setFill()
                    NSBezierPath(roundedRect: bgRect, xRadius: cornerRadius, yRadius: cornerRadius).fill()
                }

                if settings.showDayNumbers {
                    let textColor: NSColor
                    if day.isToday {
                        textColor = settings.backgroundColor
                    } else if isProgressMode && day.isPast && day.isCurrentMonth {
                        textColor = settings.textColor.withAlphaComponent(0.9)
                    } else if day.isCurrentMonth {
                        textColor = settings.textColor
                    } else {
                        textColor = settings.weekdayColor
                    }

                    let font = day.isToday ? todayFont : dayFont
                    let text = "\(day.dayNumber)"
                    let strSize = measureText(text, font: font)
                    drawText(text, at: NSPoint(x: centerX - strSize.width / 2, y: centerY - strSize.height / 2), font: font, color: textColor)
                }

                if !day.events.isEmpty {
                    let dotRadius: CGFloat = cellSize * 0.04
                    let dotSpacing: CGFloat = dotRadius * 3
                    let dotCount = min(day.events.count, Constants.maxEventDotsPerDay)
                    let totalDotsWidth = CGFloat(dotCount) * dotRadius * 2 + CGFloat(dotCount - 1) * dotRadius
                    let dotStartX = centerX - totalDotsWidth / 2

                    for i in 0..<dotCount {
                        let dotX = dotStartX + CGFloat(i) * dotSpacing
                        let dotY = centerY + cellSize * 0.3
                        let dotColor = NSColor(hex: day.events[i].color)
                        dotColor.setFill()
                        NSBezierPath(ovalIn: NSRect(x: dotX, y: dotY, width: dotRadius * 2, height: dotRadius * 2)).fill()
                    }
                }
            }
        }
    }

    private func drawText(_ text: String, at point: NSPoint, font: NSFont, color: NSColor) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        let attrStr = NSAttributedString(string: text, attributes: attrs)
        let size = attrStr.size()

        NSGraphicsContext.saveGraphicsState()
        let transform = NSAffineTransform()
        transform.translateX(by: point.x, yBy: point.y + size.height)
        transform.scaleX(by: 1, yBy: -1)
        transform.concat()
        attrStr.draw(at: .zero)
        NSGraphicsContext.restoreGraphicsState()
    }

    private func measureText(_ text: String, font: NSFont) -> NSSize {
        let attrs: [NSAttributedString.Key: Any] = [.font: font]
        return NSAttributedString(string: text, attributes: attrs).size()
    }

    private func truncateText(_ text: String, font: NSFont, maxWidth: CGFloat) -> String {
        var result = text
        while measureText(result, font: font).width > maxWidth && result.count > 1 {
            result = String(result.dropLast(2)) + "…"
        }
        return result
    }
}
