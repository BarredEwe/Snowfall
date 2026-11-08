import simd
import Foundation

enum SnowSimulation {
    static func initialize(count: Int, uniforms u: SnowUniforms) -> [Snowflake] {
        (0..<count).map { id in
            let size = u.minSize + random(id + 1, u.time) * (u.maxSize - u.minSize)
            return Snowflake(
                position: SIMD2(random(id, u.time) * (u.screenSize.x + 400) - 200,
                                random(id * 2, u.time) * u.screenSize.y),
                velocity: SIMD2(0, u.minSpeed + random(id + 3, u.time) * (u.maxSpeed - u.minSpeed)),
                color: SIMD4(1, 1, 1, max(0.2, size / u.maxSize)), size: size)
        }
    }

    static func update(_ flakes: inout [Snowflake], uniforms u: SnowUniforms) {
        let step = u.deltaTime * 60
        let wind = u.windStrength * 0.05 * step
        flakes.withUnsafeMutableBufferPointer { buffer in
            for id in buffer.indices {
                var flake = buffer[id]
                let onWindow = u.isWindowInteractionEnabled
                    && flake.position.x >= u.windowRect.x
                    && flake.position.x <= u.windowRect.x + u.windowRect.z
                    && flake.position.y >= u.windowRect.y
                    && flake.position.y <= u.windowRect.y + u.windowRect.w
                if onWindow {
                    flake.position += flake.velocity * (0.1 * step)
                    flake.size -= 0.1 * step
                    if flake.size <= 0.5 {
                        flake.position.y = -10
                        flake.position.x = random(id, u.time) * (u.screenSize.x + 400) - 200
                        flake.size = u.minSize + random(id + 1, u.time) * (u.maxSize - u.minSize)
                    }
                } else {
                    flake.position += flake.velocity * step
                    flake.position.x += wind * flake.size
                    let direction = flake.position - u.mousePosition
                    let distanceSquared = simd_length_squared(direction)
                    if distanceSquared > 0 && distanceSquared < 2500 {
                        let distance = sqrt(distanceSquared)
                        let force = (50 - distance) / 50
                        flake.position += direction / distance * (force * 20 * step)
                    }
                    if flake.position.y > u.screenSize.y + flake.size {
                        flake.position.y = -flake.size
                        flake.position.x = random(id, u.time) * (u.screenSize.x + 400) - 200
                    }
                    if flake.position.x > u.screenSize.x + 200 {
                        flake.position.x = -100
                    } else if flake.position.x < -200 {
                        flake.position.x = u.screenSize.x + 100
                    }
                }
                buffer[id] = flake
            }
        }
    }

    private static func random(_ seed: Int, _ time: Float) -> Float {
        let value = sin(Float(seed) * 12.9898 + time) * 43758.5453
        return value - floor(value)
    }
}
