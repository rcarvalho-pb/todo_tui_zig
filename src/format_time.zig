const std = @import("std");
const print = std.debug.print;

const Allocator = std.mem.Allocator;

pub fn formatDate(buffer: []u8, timestamp_ms: i64) ![]u8 {
    print("timestamp: {d}\n", .{timestamp_ms});
    // 1. Converter milissegundos para segundos
    const timestamp_s: u64 = @intCast(@divTrunc(timestamp_ms, 1000));

    // 2. Criar a estrutura EpochSeconds
    const epoch_seconds = std.time.epoch.EpochSeconds{ .secs = timestamp_s };

    // 3. Obter o dia do ano/época e os segundos do dia
    const epoch_day = epoch_seconds.getEpochDay();
    const day_seconds = epoch_seconds.getDaySeconds();

    // 4. Calcular Ano, Mês e Dia (UTC)
    const year_day = epoch_day.calculateYearDay();
    const month_day = year_day.calculateMonthDay();

    const year = year_day.year;
    const month = month_day.month.numeric(); // Returns 1-12
    const day = month_day.day_index + 1;    // Index base 0, soma +1 para o dia do mês

    // 5. Calcular Hora, Minuto e Segundo
    const hours = day_seconds.getHoursIntoDay();
    const minutes = day_seconds.getMinutesIntoHour();
    const seconds = day_seconds.getSecondsIntoMinute();

    // 6. Imprimir formatado (YYYY-MM-DD HH:MM:SS)
    return try std.fmt.bufPrint(buffer, "{d:0>2}-{d:0>2}-{d:0>4} {d:0>2}:{d:0>2}:{d:0>2} UTC\n", .{
        day,
        month,
        year,
        hours,
        minutes,
        seconds,
    });
}

pub fn formatDurationMs(buffer: []u8, ms: i64) ![]u8 {
    // if (ms < 0) return try allocator.dupe(u8, "00:00:00");
    if (ms < 0) return std.fmt.bufPrint(buffer, "00:00:00", .{});

    const total_seconds: u64 = @intCast(@divTrunc(ms, 1000));

    const seconds = total_seconds % 60;
    const total_minutes = total_seconds / 60;
    const minutes = total_minutes % 60;
    const total_hours = total_minutes / 60;

    if (total_hours < 24) {
        return try std.fmt.bufPrint(buffer, "{d:0>2}:{d:0>2}:{d:0>2}", .{ total_hours, minutes, seconds });
    }

    const days = total_hours / 24;
    const hours = total_hours % 24;

    return try std.fmt.bufPrint(buffer, "{d}d {d:0>2}:{d:0>2}:{d:0>2}", .{ days, hours, minutes, seconds });
}
